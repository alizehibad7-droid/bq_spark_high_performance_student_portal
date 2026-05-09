import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currentUserId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Leaderboard"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.streamLeaderboardUsers(),
        builder: (context, AsyncSnapshot<List<UserModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load leaderboard right now.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textGray),
                ),
              ),
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No leaderboard data yet.',
                style: TextStyle(color: AppColors.textGray),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (_, index) {
              final user = users[index];
              final isCurrentUser = user.id == currentUserId;

              return ListTile(
                tileColor: isCurrentUser
                    ? AppColors.secondary.withValues(alpha: 0.2)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  user.name.isEmpty ? 'Student' : user.name,
                  style: const TextStyle(color: AppColors.textDark),
                ),
                subtitle: Text(
                  user.studentId,
                  style: const TextStyle(color: AppColors.textGray),
                ),
                trailing: Text(
                  "${user.totalPoints} pts",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
