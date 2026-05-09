import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'BQ Spark';
      final body = message.notification?.body ?? '';
      await _showLocalNotification(title: title, body: body);
      await addNotification(title: title, body: body, sentBy: 'system');
    });
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    // Client apps cannot reliably broadcast FCM to all users.
    // This stores the notification in Firestore. Use Cloud Functions/Admin SDK
    // to send actual push to all tokens.
    await addNotification(title: title, body: body, sentBy: sentBy);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotifications() {
    return _db
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRecentNotifications({
    int limit = 5,
  }) {
    return _db
        .collection('notifications')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    required String sentBy,
  }) async {
    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'sentBy': sentBy,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bq_spark_channel',
      'BQ Spark Notifications',
      channelDescription: 'Task and admin announcements',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
  }
}
