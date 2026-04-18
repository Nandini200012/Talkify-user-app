import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebhookService {
  static const String _functionsBaseUrl =
      'https://us-central1-your-project.cloudfunctions.net';

  static bool get isMockMode => _functionsBaseUrl.contains('your-project');

  Future<bool> startCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String receiverToken,
    required String channelName,
    required String callType,
  }) async {
    if (_functionsBaseUrl.contains('your-project')) {
      debugPrint(
        '!! [WebhookService] Placeholder URL detected. Entering MOCK MODE !!',
      );
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        await FirebaseFirestore.instance
            .collection('calls')
            .doc(channelName)
            .set({
              'callId': channelName,
              'callerId': callerId,
              'callerName': callerName,
              'receiverId': receiverId,
              'channelName': channelName,
              'callType': callType,
              'status': 'ringing',
              'timestamp': DateTime.now().toIso8601String(),
              'agoraToken': '',
            });

        debugPrint('!! [WebhookService] Mock call creation successful !!');
        return true;
      } catch (e) {
        debugPrint('!! [WebhookService] Mock call creation failed: $e !!');
        return false;
      }
    }

    try {
      debugPrint('Triggering startCall webhook...');
      final response = await http
          .post(
            Uri.parse('$_functionsBaseUrl/startCall'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'callerId': callerId,
              'callerName': callerName,
              'receiverId': receiverId,
              'receiverToken': receiverToken,
              'channelName': channelName,
              'callType': callType,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('startCall webhook success');
        return true;
      } else {
        debugPrint('startCall webhook failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error triggering startCall webhook: $e');
      return false;
    }
  }

  Future<void> triggerCallEvent({
    required String event,
    required Map<String, dynamic> callData,
  }) async {
    if (_functionsBaseUrl.contains('your-project')) return;

    try {
      debugPrint('Triggering Webhook Event: $event');
      await http
          .post(
            Uri.parse('$_functionsBaseUrl/handleCallEvent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'event': event, 'data': callData}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Webhook Error: $e');
    }
  }
}
