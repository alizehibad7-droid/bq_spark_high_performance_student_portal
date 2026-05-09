import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class StudentProvider extends ChangeNotifier {
  StudentProvider(this._authService, this._firestoreService);

  final AuthService _authService;
  final FirestoreService _firestoreService;

  UserModel? _student;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel?>? _studentSub;

  UserModel? get student => _student;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentStudent() async {
    final user = _authService.currentUser;
    if (user == null) {
      _student = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _studentSub?.cancel();
      _studentSub = _firestoreService.streamUserById(user.uid).listen((data) {
        _student = data;
        _isLoading = false;
        notifyListeners();
      });
    } catch (_) {
      _error = 'Could not load student profile.';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _studentSub?.cancel();
    super.dispose();
  }
}
