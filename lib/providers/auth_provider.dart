import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _subscription = _authService.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _authService.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => currentUser != null;

  Future<bool> loginWithStudentId(String studentId, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.loginStudent(studentId, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed. Please try again.';
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected error. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
