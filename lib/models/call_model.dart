class Call {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerPic;
  final String receiverId;
  final String receiverName;
  final String receiverPic;
  final String channelName;
  final String callType;
  final String status;
  final String timestamp;
  final String? agoraToken;

  Call({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerPic,
    required this.receiverId,
    required this.receiverName,
    required this.receiverPic,
    required this.channelName,
    required this.callType,
    required this.status,
    required this.timestamp,
    this.agoraToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'callerId': callerId,
      'callerName': callerName,
      'callerPic': callerPic,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPic': receiverPic,
      'channelName': channelName,
      'callType': callType,
      'status': status,
      'timestamp': timestamp,
      'agoraToken': agoraToken,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map) {
    return Call(
      callId: map['callId'] ?? '',
      callerId: map['callerId'] ?? '',
      callerName: map['callerName'] ?? '',
      callerPic: map['callerPic'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverPic: map['receiverPic'] ?? '',
      channelName: map['channelName'] ?? '',
      callType: map['callType'] ?? 'audio',
      status: map['status'] ?? 'ringing',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      agoraToken: map['agoraToken'],
    );
  }

  Call copyWith({String? status}) {
    return Call(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      callerPic: callerPic,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverPic: receiverPic,
      channelName: channelName,
      callType: callType,
      status: status ?? this.status,
      timestamp: timestamp,
      agoraToken: agoraToken ?? this.agoraToken,
    );
  }
}
