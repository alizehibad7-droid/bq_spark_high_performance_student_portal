import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'leaderboard_screen.dart';
import 'resources_screen.dart';
import 'profile_screen.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(),
    LeaderboardScreen(),
    ResourcesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.uid;
      if (userId == null) {
        return;
      }
      context.read<StudentProvider>().loadCurrentStudent();
      context.read<TaskProvider>().watchTasksForUser(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGray,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined), label: 'Ranks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined), label: 'Resources'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}