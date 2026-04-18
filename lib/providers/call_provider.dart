import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/firestore_service.dart';
import '../services/webhook_service.dart';
import '../models/call_model.dart';
import '../models/user_model.dart';

class CallProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final WebhookService _webhookService = WebhookService();

  static const String agoraAppId = "96329987950b40fd9ee8a20dad682cdb";

  Call? _currentCall;
  RtcEngine? _engine;
  bool _isEngineInitialized = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isRemoteVideoOff = false;
  bool _isSpeakerOn = false;
  int _duration = 0;
  Timer? _timer;
  StreamSubscription? _incomingCallSubscription;
  bool _isListeningToCalls = false;
  String? _lastListeningUid;

  Call? get currentCall => _currentCall;
  RtcEngine? get engine => _engine;
  bool get isEngineInitialized => _isEngineInitialized;
  bool get localUserJoined => _localUserJoined;
  int? get remoteUid => _remoteUid;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isRemoteVideoOff => _isRemoteVideoOff;
  bool get isSpeakerOn => _isSpeakerOn;
  int get duration => _duration;

  String get formattedDuration {
    int minutes = _duration ~/ 60;
    int seconds = _duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> requestPermissions() async {
    if (_currentCall?.callType == 'video') {
      await [Permission.camera, Permission.microphone].request();
    } else {
      await Permission.microphone.request();
    }
  }

  Future<void> initAgora() async {
    if (_isEngineInitialized || _currentCall == null) return;

    await requestPermissions();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _localUserJoined = true;
          _startTimer();
          _engine?.setEnableSpeakerphone(_isSpeakerOn);
          notifyListeners();
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          _remoteUid = remoteUid;
          notifyListeners();
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              _remoteUid = null;
              _isRemoteVideoOff = false;
              notifyListeners();
              if (reason == UserOfflineReasonType.userOfflineQuit) {
                endCall(_currentCall!.callId);
              }
            },
        onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
          _isRemoteVideoOff = muted;
          notifyListeners();
        },
      ),
    );

    if (_currentCall!.callType == 'video') {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.enableAudio();
    }

    await _engine!.joinChannel(
      token: _currentCall!.agoraToken ?? '',
      channelId: _currentCall!.channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: _currentCall!.callType == 'video',
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: _currentCall!.callType == 'video',
      ),
    );

    _isEngineInitialized = true;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _duration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      notifyListeners();
    });
  }

  Future<void> makeCall({
    required UserModel caller,
    required UserModel receiver,
    required String callType,
  }) async {
    final channelName = const Uuid().v4();

    String? receiverToken = await _firestoreService.getUserFcmToken(
      receiver.uid,
    );

    if (receiverToken == null || receiverToken.isEmpty) {
      if (WebhookService.isMockMode) {
        debugPrint(
          "Warning: Receiver FCM token not found, but proceeding with Mock Token",
        );
        receiverToken = "mock_token_for_${receiver.name}";
      } else {
        debugPrint("Error: Receiver FCM token not found for ${receiver.name}");
        return;
      }
    }

    _currentCall = Call(
      callId: channelName,
      callerId: caller.uid,
      callerName: caller.name,
      callerPic: '',
      receiverId: receiver.uid,
      receiverName: receiver.name,
      receiverPic: '',
      channelName: channelName,
      callType: callType,
      status: 'ringing',
      timestamp: DateTime.now().toIso8601String(),
    );
    notifyListeners();

    final success = await _webhookService.startCall(
      callerId: caller.uid,
      callerName: caller.name,
      receiverId: receiver.uid,
      receiverToken: receiverToken,
      channelName: channelName,
      callType: callType,
    );

    if (!success) {
      debugPrint("Error: Failed to trigger startCall webhook");
      _cleanupCall();
      return;
    }

    _listenToCallStatus(channelName);
  }

  String? _lastListenedCallId;

  void _listenToCallStatus(String callId) {
    if (_lastListenedCallId == callId) return;
    _lastListenedCallId = callId;

    _firestoreService.listenToCall(callId).listen((updatedCall) {
      if (updatedCall != null) {
        _currentCall = updatedCall;
        notifyListeners();

        if (updatedCall.status == 'accepted' && !_isEngineInitialized) {
          initAgora();
        }

        if (updatedCall.status == 'rejected' || updatedCall.status == 'ended') {
          Future.delayed(const Duration(seconds: 2), () {
            _cleanupCall();
          });
        }
      }
    });
  }

  void listenToIncomingCalls(String currentUid) {
    if (_isListeningToCalls && _lastListeningUid == currentUid) return;

    _incomingCallSubscription?.cancel();
    _lastListeningUid = currentUid;
    _isListeningToCalls = true;

    _incomingCallSubscription = _firestoreService
        .listenToIncomingCalls(currentUid)
        .listen((incomingCall) {
          if (incomingCall != null && _currentCall == null) {
            _currentCall = incomingCall;
            notifyListeners();
            _listenToCallStatus(incomingCall.callId);
          }
        });
  }

  Future<void> acceptCall(String callId) async {
    await _webhookService.triggerCallEvent(
      event: 'update',
      callData: {'callId': callId, 'status': 'accepted'},
    );
    await _firestoreService.updateCallStatus(callId, 'accepted');
    initAgora();
  }

  Future<void> rejectCall(String callId) async {
    await _webhookService.triggerCallEvent(
      event: 'update',
      callData: {'callId': callId, 'status': 'rejected'},
    );
    await _firestoreService.updateCallStatus(callId, 'rejected');
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(status: 'rejected');
      notifyListeners();
    }
  }

  Future<void> endCall(String callId) async {
    await _webhookService.triggerCallEvent(
      event: 'end',
      callData: {'callId': callId, 'status': 'ended'},
    );
    await _firestoreService.updateCallStatus(callId, 'ended');
    if (_currentCall != null) {
      _currentCall = _currentCall!.copyWith(status: 'ended');
      notifyListeners();
    }
  }

  void _cleanupCall() async {
    _timer?.cancel();
    _timer = null;
    _duration = 0;

    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }

    _isEngineInitialized = false;
    _localUserJoined = false;
    _remoteUid = null;
    _currentCall = null;
    _lastListenedCallId = null;
    _isVideoOff = false;
    _isRemoteVideoOff = false;
    _isMuted = false;
    _isSpeakerOn = false;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _engine?.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoOff = !_isVideoOff;
    _engine?.muteLocalVideoStream(_isVideoOff);
    _engine?.enableLocalVideo(!_isVideoOff);
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _engine?.setEnableSpeakerphone(_isSpeakerOn);
    notifyListeners();
  }

  void switchCamera() {
    _engine?.switchCamera();
  }

  @override
  void dispose() {
    _cleanupCall();
    super.dispose();
  }
}
