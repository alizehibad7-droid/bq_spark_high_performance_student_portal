import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance =
      RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final FirebaseRemoteConfig _config = FirebaseRemoteConfig.instance;

  // Default values — admin can change these
  // from Firebase Console anytime
  static const Map<String, dynamic> _defaults = {
    'welcome_message': 'Welcome to BQ Spark!',
    'leaderboard_enabled': true,
    'news_feed_enabled': true,
    'max_tasks_per_student': 20,
    'announcement_banner': '',
    'maintenance_mode': false,
    'groq_api_key': '',
  };

  Future<void> init() async {
    try {
      await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _config.setDefaults(_defaults);
      await _config.fetchAndActivate();
      debugPrint('Remote Config initialized successfully');
    } catch (e) {
      debugPrint('Remote Config error: $e');
    }
  }

  String get welcomeMessage => _config.getString('welcome_message');

  bool get leaderboardEnabled => _config.getBool('leaderboard_enabled');

  bool get newsFeedEnabled => _config.getBool('news_feed_enabled');

  int get maxTasksPerStudent => _config.getInt('max_tasks_per_student');

  String get announcementBanner => _config.getString('announcement_banner');

  bool get maintenanceMode => _config.getBool('maintenance_mode');

  String get groqApiKey => _config.getString('groq_api_key');
}
