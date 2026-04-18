import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isInitializing = true;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;

  AuthProvider() {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _userModel = await _firestoreService.getUser(user.uid);
        if (_userModel != null) {
          _firestoreService.updateUserStatus(user.uid, true);
          _updateFcmToken(user.uid);
        }
      }
      _isInitializing = false;
      notifyListeners();
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.signUp(email, password);
      if (credential?.user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        final newUser = UserModel(
          uid: credential!.user!.uid,
          name: name,
          email: email,
          isOnline: true,
          fcmToken: fcmToken,
        );
        await _firestoreService.createUser(newUser);

        await logout();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final credential = await _authService.login(email, password);
      if (credential?.user != null) {
        _userModel = await _firestoreService.getUser(credential!.user!.uid);
        if (_userModel != null) {
          await _firestoreService.updateUserStatus(_userModel!.uid, true);
          await _updateFcmToken(_userModel!.uid);
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      await _firestoreService.updateUserStatus(_user!.uid, false);
    }
    await _authService.logout();
    _user = null;
    _userModel = null;
    notifyListeners();
  }

  void updateOnlineStatus(bool isOnline) {
    if (_user != null) {
      _firestoreService.updateUserStatus(_user!.uid, isOnline);
    }
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestoreService.updateFcmToken(uid, token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _firestoreService.updateFcmToken(uid, newToken);
      });
    } catch (e) {
      debugPrint("Error updating FCM token: $e");
    }
  }
}
