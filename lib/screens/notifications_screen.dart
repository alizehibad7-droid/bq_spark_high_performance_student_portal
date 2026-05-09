import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Notifications")),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: context.read<NotificationService>().streamNotifications(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (_, index) {

              final data = notifications[index].data();

              return Card(
                child: ListTile(
                  title: Text(data['title'] ?? ''),
                  subtitle: Text(data['body'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}