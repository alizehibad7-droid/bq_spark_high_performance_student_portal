// File: lib/services/auth_service.dart
// Handles all Firebase Authentication logic for BQ Spark

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _bootstrapAdminEmail = 'aleeza@gmail.com';

  // Convert BQ-HP-001 -> bq-hp-001 for stable matching.
  String _normalizeStudentId(String studentId) {
    return studentId.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }

  // Convert BQ-HP-001 -> bq-hp-001@bqspark.com for fallback login.
  String _toFallbackEmail(String studentId) {
    return '${_normalizeStudentId(studentId)}@bqspark.com';
  }

  // Get currently logged in user
  User? get currentUser => _auth.currentUser;

  // Auth state stream — used to check if user is logged in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Student Login ───────────────────────────────────────
  Future<UserCredential> loginStudent(String studentId, String password) async {
    final normalizedId = _normalizeStudentId(studentId);
    final resolvedEmail = await _findStudentEmailById(normalizedId);
    final fallbackEmail = _toFallbackEmail(studentId);
    final candidateEmails = <String>[
      if (resolvedEmail != null && resolvedEmail.isNotEmpty) resolvedEmail,
      fallbackEmail,
    ];
    FirebaseAuthException? lastAuthException;

    for (final email in candidateEmails.toSet()) {
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        lastAuthException = e;
        if (e.code != 'user-not-found') {
          rethrow;
        }
      }
    }

    if (lastAuthException != null) {
      throw lastAuthException;
    }
    throw FirebaseAuthException(
      code: 'user-not-found',
      message: 'No student account found for this Student ID.',
    );
  }

  Future<String?> _findStudentEmailById(String normalizedStudentId) async {
    final userQuery = await _db
        .collection('users')
        .where('studentIdNormalized', isEqualTo: normalizedStudentId)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return null;
    final email = userQuery.docs.first.data()['email'];
    if (email is String && email.trim().isNotEmpty) {
      return email.trim().toLowerCase();
    }
    return null;
  }

  // ─── Student Signup ──────────────────────────────────────
  Future<UserCredential> signupStudent({
    required String studentId,
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedId = _normalizeStudentId(studentId);
    final emailValue = email.trim().toLowerCase();
    final fallbackEmail = _toFallbackEmail(studentId);

    final existingByStudentId = await _db
        .collection('users')
        .where('studentIdNormalized', isEqualTo: normalizedId)
        .limit(1)
        .get();

    if (existingByStudentId.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'student-id-already-in-use',
        message: 'This Student ID is already registered.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: emailValue,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'studentId': studentId.trim(),
      'studentIdNormalized': normalizedId,
      'name': name.trim(),
      'email': emailValue,
      'loginEmailAlias': fallbackEmail,
      'role': 'student',
      'githubLink': '',
      'totalPoints': 0,
      'currentStage': 1,
      'profileImage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Student role saved as student for uid: ${cred.user!.uid}');

    return cred;
  }

  // ─── Student Forgot Password ─────────────────────────────
  Future<void> sendPasswordResetByEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Deprecated path kept for backwards compatibility.
  Future<void> sendStudentPasswordReset(String studentId) async {
    final normalizedId = _normalizeStudentId(studentId);
    final query = await _db
        .collection('users')
        .where('studentIdNormalized', isEqualTo: normalizedId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No student found with this Student ID.',
      );
    }

    final email = query.docs.first.data()['email'] as String?;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'No valid email linked with this Student ID.',
      );
    }

    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Admin Login ─────────────────────────────────────────
  Future<UserCredential> loginAdmin({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No authenticated user found after login.',
      );
    }

    await _createBootstrapAdminIfMissing(
      uid: user.uid,
      name: '',
      email: email.trim().toLowerCase(),
    );

    final data = await getCurrentUserData();
    if (data == null || data['role'] != 'admin') {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'This account is not authorized as admin.',
      );
    }

    return cred;
  }

  Future<void> _createBootstrapAdminIfMissing({
    required String uid,
    required String name,
    required String email,
  }) async {
    // Auto-seed the known admin account in Firestore once.
    if (email.trim().toLowerCase() != _bootstrapAdminEmail) {
      return;
    }

    final userRef = _db.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      return;
    }

    await userRef.set({
      'uid': uid,
      'name': name.isEmpty ? 'Admin' : name,
      'email': email.trim(),
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Get current user data from Firestore ────────────────
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ─── Logout ──────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Admin: Create a new student account ─────────────────
  Future<void> createStudent({
    required String studentId,
    required String name,
    required String password,
  }) async {
    final email = _toFallbackEmail(studentId);
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'studentId': studentId,
      'studentIdNormalized': _normalizeStudentId(studentId),
      'name': name,
      'email': email,
      'role': 'student',
      'githubLink': '',
      'totalPoints': 0,
      'currentStage': 1,
      'profileImage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint(
      'Admin-created student role saved as student for uid: ${cred.user!.uid}',
    );
  }

  // ─── Admin-safe create student without switching admin session ───
  Future<void> createStudentByAdmin({
    required String studentId,
    required String name,
    required String password,
  }) async {
    final email = _toFallbackEmail(studentId);
    final normalizedId = _normalizeStudentId(studentId);
    final existingByStudentId = await _db
        .collection('users')
        .where('studentIdNormalized', isEqualTo: normalizedId)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();
    if (existingByStudentId.docs.isNotEmpty) {
      throw FirebaseAuthException(
        code: 'student-id-already-in-use',
        message: 'This Student ID is already registered.',
      );
    }

    const appName = 'bq-spark-admin-create-user';
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = Firebase.app(appName);
    } catch (_) {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'studentId': studentId,
      'studentIdNormalized': normalizedId,
      'name': name,
      'email': email,
      'loginEmailAlias': email,
      'role': 'student',
      'githubLink': '',
      'totalPoints': 0,
      'currentStage': 1,
      'profileImage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await secondaryAuth.signOut();
  }

  // ─── Check if current user is admin ──────────────────────
  Future<bool> isAdmin() async {
    final data = await getCurrentUserData();
    return data?['role'] == 'admin';
  }
}
