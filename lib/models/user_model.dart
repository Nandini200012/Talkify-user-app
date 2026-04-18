class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isOnline;
  final String? fcmToken;
  final List<String> connections;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.isOnline,
    this.fcmToken,
    this.connections = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'connections': connections,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'],
      connections: List<String>.from(map['connections'] ?? []),
    );
  }
}
