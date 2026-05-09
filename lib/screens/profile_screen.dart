import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _githubController = TextEditingController();
  bool _isSaving = false;
  String? _boundUserId;

  Future<void> openGithub(String github) async {
    if (github.isEmpty) return;
    final uri = Uri.tryParse(github);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  void _syncControllers({
    required String userId,
    required String name,
    required String github,
  }) {
    if (_boundUserId == userId) return;
    _boundUserId = userId;
    _nameController.text = name;
    _githubController.text = github;
  }

  Future<void> _saveProfile({
    required String userId,
    required String currentName,
    required String currentGithub,
  }) async {
    final name = _nameController.text.trim();
    final github = _githubController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    if (name == currentName.trim() && github == currentGithub.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to update')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<FirestoreService>().updateUserProfile(
        userId: userId,
        name: name,
        githubLink: github,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>().student;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.uid;
    final github = student?.githubLink ?? '';
    final name = student?.name ?? '';

    if (userId != null) {
      _syncControllers(userId: userId, name: name, github: github);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showConfirmationDialog(
                context,
                title: 'Logout',
                message: 'Are you sure you want to logout?',
                confirmLabel: 'Logout',
                isDestructive: true,
              );
              if (!confirm) return;
              await fb_auth.FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: student == null || userId == null
            ? const Center(
                child: Text(
                  'Profile not available.',
                  style: TextStyle(color: AppColors.textGray),
                ),
              )
            : ListView(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    child: Icon(Icons.person, size: 40),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    student.name.isNotEmpty ? student.name : "Student Name",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Student ID: ${student.studentId.isNotEmpty ? student.studentId : 'N/A'}",
                    style: const TextStyle(color: AppColors.textGray),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _githubController,
                    decoration: const InputDecoration(
                      labelText: 'GitHub Link',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveProfile(
                              userId: userId,
                              currentName: student.name,
                              currentGithub: student.githubLink,
                            ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save / Update'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(Icons.code),
                    title: const Text("GitHub Profile"),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _githubController.text.trim().isEmpty
                        ? null
                        : () => openGithub(_githubController.text.trim()),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text("Total Points"),
                    trailing: Text("${student.totalPoints}"),
                  ),

                  ListTile(
                    leading: const Icon(Icons.trending_up),
                    title: const Text("Current Stage"),
                    trailing: Text("Stage ${student.currentStage}"),
                  ),
                ],
              ),
      ),
    );
  }
}
