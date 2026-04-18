import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/call_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  Future<String?> getUserFcmToken(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['fcmToken'];
    }
    return null;
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  Stream<List<UserModel>> getAllUsers(String currentUid) {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .where((user) => user.uid != currentUid)
          .toList();
    });
  }

  Future<void> updateUserStatus(String uid, bool isOnline) async {
    await _db.collection('users').doc(uid).set({
      'isOnline': isOnline,
    }, SetOptions(merge: true));
  }

  Future<void> toggleConnection(
    String currentUid,
    String otherUid,
    bool isConnecting,
  ) async {
    if (isConnecting) {
      await _db.collection('users').doc(currentUid).set({
        'connections': FieldValue.arrayUnion([otherUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(otherUid).set({
        'connections': FieldValue.arrayUnion([currentUid]),
      }, SetOptions(merge: true));
    } else {
      await _db.collection('users').doc(currentUid).set({
        'connections': FieldValue.arrayRemove([otherUid]),
      }, SetOptions(merge: true));
      await _db.collection('users').doc(otherUid).set({
        'connections': FieldValue.arrayRemove([currentUid]),
      }, SetOptions(merge: true));
    }
  }

  Future<void> makeCall(Call call) async {
    await _db.collection('calls').doc(call.callId).set(call.toMap());
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _db.collection('calls').doc(callId).update({'status': status});
  }

  Stream<Call?> listenToCall(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return Call.fromMap(doc.data()!);
      }
      return null;
    });
  }

  Stream<Call?> listenToIncomingCalls(String receiverId) {
    return _db
        .collection('calls')
        .where('receiverId', isEqualTo: receiverId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final results = snapshot.docs.where((doc) {
              final data = doc.data();
              if (data['timestamp'] == null) return false;

              DateTime callTime;
              final ts = data['timestamp'];
              if (ts is Timestamp) {
                callTime = ts.toDate();
              } else if (ts is String) {
                callTime = DateTime.parse(ts);
              } else {
                return false;
              }

              final diff = DateTime.now().difference(callTime).abs();
              return diff.inMinutes < 1;
            }).toList();

            if (results.isNotEmpty) {
              return Call.fromMap(results.first.data());
            }
          }
          return null;
        });
  }
}
