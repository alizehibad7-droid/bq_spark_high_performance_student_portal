import 'package:firebase_auth/firebase_auth.dart';

class FirebaseErrorMapper {
  static String mapAuthError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for these credentials.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect credentials. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'student-id-already-in-use':
        return 'This Student ID is already registered.';
      case 'operation-not-allowed':
        return error.message ?? 'Operation not allowed.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
