import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../providers/call_provider.dart';
import '../providers/auth_provider.dart';
import '../models/call_model.dart';

class CallScreen extends StatelessWidget {
  final Call call;
  const CallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid ?? authProvider.user?.uid;
    final isCaller = call.callerId == currentUserId;

    if (call.status == 'ringing') {
      return _buildRingingUI(context, isCaller, callProvider);
    }

    if (call.status == 'rejected') {
      return _buildRejectedUI(context);
    }

    if (call.status == 'ended') {
      return _buildEndedUI(context);
    }

    return _buildCallUI(context, callProvider);
  }

  Widget _buildEndedUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_end, color: Colors.white54, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Call Ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_end, color: Colors.redAccent, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Call Declined',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingingUI(
    BuildContext context,
    bool isCaller,
    CallProvider callProvider,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A32), Color(0xFF0F0F1E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 80,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isCaller ? "Calling ${call.receiverName}..." : call.callerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              isCaller
                  ? "Outgoing ${call.callType} call"
                  : "Incoming ${call.callType} call",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isCaller)
                  _circleButton(
                    Icons.call,
                    Colors.green,
                    () => callProvider.acceptCall(call.callId),
                    label: 'Accept',
                  ),
                _circleButton(
                  Icons.call_end,
                  Colors.red,
                  () => isCaller
                      ? callProvider.endCall(call.callId)
                      : callProvider.rejectCall(call.callId),
                  label: isCaller ? 'Cancel' : 'Decline',
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCallUI(BuildContext context, CallProvider callProvider) {
    final isVideo = call.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video or Audio Placeholder
          Positioned.fill(child: _remoteVideo(context, callProvider)),

          // Local Video (Floating)
          if (isVideo)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      callProvider.localUserJoined &&
                          callProvider.engine != null
                      ? (callProvider.isVideoOff
                            ? Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(
                                    Icons.videocam_off,
                                    color: Colors.white54,
                                    size: 30,
                                  ),
                                ),
                              )
                            : AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: callProvider.engine!,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              ))
                      : Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
              ),
            ),

          // Call Info (Name and Duration)
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  call.callerId ==
                          Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).user?.uid
                      ? call.receiverName
                      : call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (call.callType == 'video') ...[
                  Text(
                    'Video Call Active',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    callProvider.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),

          _buildToolbar(callProvider),
        ],
      ),
    );
  }

  Widget _remoteVideo(BuildContext context, CallProvider callProvider) {
    if (call.callType == 'audio') {
      return Container(
        color: const Color(0xFF0F0F1E),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Audio Call Active',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                callProvider.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (callProvider.remoteUid != null && callProvider.engine != null) {
      if (callProvider.isRemoteVideoOff) {
        return Container(
          color: const Color(0xFF0F0F1E),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Remote Camera Off',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: callProvider.engine!,
          canvas: VideoCanvas(uid: callProvider.remoteUid),
          connection: RtcConnection(channelId: call.channelName),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Waiting for other user to join...",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildToolbar(CallProvider callProvider) {
    final isVideo = call.callType == 'video';

    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _circleButton(
                callProvider.isMuted ? Icons.mic_off : Icons.mic,
                callProvider.isMuted ? Colors.red.shade400 : Colors.white24,
                callProvider.toggleMute,
                label: 'Mute',
              ),
              _circleButton(
                callProvider.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                callProvider.isSpeakerOn
                    ? Colors.green.shade700
                    : Colors.white24,
                callProvider.toggleSpeaker,
                label: 'Speaker',
              ),
              if (isVideo) ...[
                _circleButton(
                  callProvider.isVideoOff ? Icons.videocam_off : Icons.videocam,
                  callProvider.isVideoOff
                      ? Colors.red.shade400
                      : Colors.white24,
                  callProvider.toggleVideo,
                  label: 'Camera',
                ),
                _circleButton(
                  Icons.switch_camera,
                  Colors.white24,
                  callProvider.switchCamera,
                  label: 'Flip',
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          RawMaterialButton(
            onPressed: () => callProvider.endCall(call.callId),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(20.0),
            child: const Icon(Icons.call_end, color: Colors.white, size: 40.0),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    Color color,
    VoidCallback onTap, {
    double size = 28,
    String? label,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: size),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
