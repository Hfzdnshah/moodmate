import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // Fetch user profile from Firestore
        try {
          _userModel = await _authService.getUserProfile(user.uid);
        } catch (e) {
          debugPrint('Error fetching user profile: $e');
          _userModel = null;
        }
      } else {
        _userModel = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refreshUser() async {
    if (_firebaseUser != null) {
      try {
        _userModel = await _authService.getUserProfile(_firebaseUser!.uid);
        notifyListeners();
      } catch (e) {
        debugPrint('Error refreshing user: $e');
      }
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }
}
