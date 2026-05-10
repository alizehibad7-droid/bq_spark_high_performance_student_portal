import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/task_provider.dart';
import 'screens/role_selection_screen.dart';
import 'screens/student/student_login_screen.dart';
import 'screens/student/student_signup_screen.dart';
import 'screens/student/student_forgot_password_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/main_nav.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/resource_service.dart';
import 'services/task_service.dart';
import 'services/remote_config_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter framework error: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Something went wrong.\n${details.exceptionAsString()}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');

    await RemoteConfigService().init();

    if (!kIsWeb) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance
            .recordError(error, stack, fatal: true);
        return true;
      };
    } else {
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter error: ${details.exceptionAsString()}');
      };
    }

    FirebaseMessaging.onBackgroundMessage(
      NotificationService.firebaseBackgroundHandler,
    );
    runApp(const BQSparkApp());
  } catch (e, st) {
    debugPrint('Startup failed: $e');
    debugPrintStack(stackTrace: st);
    runApp(StartupErrorApp(errorMessage: e.toString()));
  }
}

class BQSparkApp extends StatefulWidget {
  const BQSparkApp({super.key});

  @override
  State<BQSparkApp> createState() => _BQSparkAppState();
}

class _BQSparkAppState extends State<BQSparkApp> {
  late final AuthService _authService;
  late final FirestoreService _firestoreService;
  late final NotificationService _notificationService;
  late final TaskService _taskService;
  late final ResourceService _resourceService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _firestoreService = FirestoreService();
    _notificationService = NotificationService();
    _taskService = TaskService();
    _resourceService = ResourceService();
    unawaited(
      _notificationService.init().catchError((Object e) {
        debugPrint('Notification init failed: $e');
      }),
    );
  }

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        Provider<FirestoreService>.value(value: _firestoreService),
        Provider<NotificationService>.value(value: _notificationService),
        Provider<TaskService>.value(value: _taskService),
        Provider<ResourceService>.value(value: _resourceService),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_authService),
        ),
        ChangeNotifierProvider<StudentProvider>(
          create: (_) => StudentProvider(_authService, _firestoreService),
        ),
        ChangeNotifierProvider<TaskProvider>(
          create: (_) => TaskProvider(_taskService),
        ),
      ],
      child: MaterialApp(
        title: 'BQ Spark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const RoleSelectionScreen(),
        routes: {
          '/role-selection': (_) => const RoleSelectionScreen(),
          '/student-login': (_) => const StudentLoginScreen(),
          '/student-signup': (_) => const StudentSignupScreen(),
          '/student-forgot-password': (_) => const StudentForgotPasswordScreen(),
          '/student-dashboard': (_) => const MainNav(),
          '/admin-login': (_) => const AdminLoginScreen(),
          '/admin-dashboard': (_) => const AdminPanelScreen(),
        },
        onUnknownRoute: (_) {
          debugPrint('Unknown route triggered. Redirecting to role selection.');
          return MaterialPageRoute(
            builder: (_) => const RoleSelectionScreen(),
          );
        },
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 44, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Startup Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}