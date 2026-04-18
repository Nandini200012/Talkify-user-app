import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _users = [];
  bool _isLoading = false;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;

  void fetchUsers(String currentUid) {
    _isLoading = true;
    _firestoreService.getAllUsers(currentUid).listen((usersList) {
      _users = usersList;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> toggleConnection(String currentUid, String otherUid, bool isConnecting) async {
    await _firestoreService.toggleConnection(currentUid, otherUid, isConnecting);
  }
}
