import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class NotificationService {
  NotificationService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  @pragma('vm:entry-point')
  static Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
    debugPrint('BG notification: ${message.notification?.title}');
  }

  Future<void> init() async {
    try {
      await _initInternal()
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('NotificationService skipped: $e');
    }
  }

  Future<void> _initInternal() async {
    if (kIsWeb) {
      debugPrint('FCM skipped on web platform');
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging
        .getToken()
        .timeout(const Duration(seconds: 5));
    debugPrint('FCM Token: $token');

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit),
    );

    const channel = AndroidNotificationChannel(
      'bq_spark_channel',
      'BQ Spark Notifications',
      description: 'HP Track student notifications',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification != null) {
        await _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'bq_spark_channel',
              'BQ Spark Notifications',
              channelDescription: 'HP Track student notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
      final title = message.notification?.title ?? 'BQ Spark';
      final body = message.notification?.body ?? '';
      await addNotification(title: title, body: body, sentBy: 'system');
    });
  }
  Future<String?> getDeviceToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }
  Future<void> sendAnnouncement({
    required String title,
    required String body,
    required String sentBy,
  }) async {
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
}
