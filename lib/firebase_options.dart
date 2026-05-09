// File: lib/firebase_options.dart
// Generated manually for BQ Spark - High Performance Student Portal
// DO NOT share this file publicly or push to GitHub without adding to .gitignore

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Only Android is supported for this app
    return android;
  }

  // ✅ Android app configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCr53mluoumKHf853c6VgA7YIL4Fxdjq18',
    appId: '1:1055142062544:android:43f83931d837c1299871d5',
    messagingSenderId: '1055142062544',
    projectId: 'bq-high-performance',
    storageBucket: 'bq-high-performance.firebasestorage.app',
  );
}