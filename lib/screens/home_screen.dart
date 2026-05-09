import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../providers/task_provider.dart';
import '../services/firestore_service.dart';
import 'admin_panel_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final firestoreService = context.read<FirestoreService>();

    final student = studentProvider.student;
    final completedCount = taskProvider.completedTaskIds.length;
    final pendingCount = (taskProvider.tasks.length - completedCount).clamp(0, 999);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("BQ Spark"),
        automaticallyImplyLeading: false,
        actions: [
          if (student?.role == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(student),
            const SizedBox(height: 16),
            _stageCard(student),
            const SizedBox(height: 16),
            _quickStatsCard(
              completedCount: completedCount,
              pendingCount: pendingCount,
              rankWidget: StreamBuilder<List<UserModel>>(
                stream: firestoreService.streamLeaderboardUsers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || authProvider.currentUser == null) {
                    return const Text('-', style: TextStyle(fontWeight: FontWeight.bold));
                  }
                  final uid = authProvider.currentUser!.uid;
                  final index =
                      snapshot.data!.indexWhere((user) => user.id == uid);
                  return Text(
                    index == -1 ? '-' : '#${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Keep going — consistency wins.",
              style: TextStyle(color: AppColors.textGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard(UserModel? student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome, ${student?.name.isNotEmpty == true ? student!.name : 'High Performer'}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            student?.studentId.isNotEmpty == true
                ? "Student ID: ${student!.studentId}"
                : "Stay consistent. Complete tasks. Lead the leaderboard.",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _stageCard(UserModel? student) {
    final currentStage = (student?.currentStage ?? 1).clamp(1, 4);
    final progress = currentStage / 4;
    const stageNames = <String>[
      'Course',
      'BQ Spark',
      'Supervised Projects',
      'Industry Placement',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Stage: $currentStage of 4',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white,
            color: AppColors.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text(
            stageNames[currentStage - 1],
            style: const TextStyle(color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _quickStatsCard({
    required int completedCount,
    required int pendingCount,
    required Widget rankWidget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Stats",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statTile('Tasks Done', '$completedCount'),
              _statTile('Pending', '$pendingCount'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rank',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                  rankWidget,
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGray),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}