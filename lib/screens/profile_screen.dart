import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/student_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/confirmation_dialog.dart';
import 'role_selection_screen.dart';

const _primary = Color(0xFF1A5C35);
const _greenAccent = Color(0xFF2E7D52);
const _gold = Color(0xFFB8A030);
const _bg = Color(0xFFF4F6F8);
const _border = Color(0xFFE5E7EB);
const _chipBg = Color(0xFFE8F4EE);

const _stageNames = <String>[
  'Course',
  'BQ Spark',
  'Supervised Projects',
  'Industry Placement',
];

const _stageSubtitles = <String>[
  'Build your foundation',
  'High performance track',
  'Ship real projects',
  'Industry experience',
];

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

  Future<void> _logout() async {
    final confirm = await showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
    if (!confirm) return;
    await fb_auth.FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'S';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
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

    if (student == null || userId == null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true,
        ),
        body: const Center(
          child: Text(
            'Profile not available.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    final displayName =
        student.name.isNotEmpty ? student.name : 'Student';
    final studentId =
        student.studentId.isNotEmpty ? student.studentId : 'N/A';
    final stage = student.currentStage.clamp(1, 4);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: true,
            leading: null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primary, _greenAccent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 24),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _gold,
                            child: Text(
                              _initials(displayName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              studentId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _statsRow(context, student, stage, userId),
                const SizedBox(height: 16),
                _journeyCard(stage),
                const SizedBox(height: 16),
                _accountCard(
                  student: student,
                  userId: userId,
                ),
                const SizedBox(height: 16),
                _skillsCard(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(
    BuildContext context,
    UserModel student,
    int stage,
    String userId,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.star_rounded,
            iconColor: _gold,
            value: '${student.totalPoints}',
            label: 'Points',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.bolt_rounded,
            iconColor: _primary,
            value: 'Stage $stage/4',
            label: 'Progress',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: context.read<FirestoreService>().streamLeaderboardUsers(),
            builder: (context, snapshot) {
              String value = 'Student';
              if (snapshot.hasData) {
                final index =
                    snapshot.data!.indexWhere((u) => u.id == userId);
                if (index != -1) {
                  value = '#${index + 1}';
                }
              }
              return _statCard(
                icon: Icons.person_rounded,
                iconColor: _greenAccent,
                value: value,
                label: 'Role',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyCard(int currentStage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Journey',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _stageRow(
              stageIndex: i + 1,
              currentStage: currentStage,
              title: _stageNames[i],
              subtitle: _stageSubtitles[i],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stageRow({
    required int stageIndex,
    required int currentStage,
    required String title,
    required String subtitle,
  }) {
    late final Widget leadingIcon;
    late final String badge;
    late final Color badgeBg;
    late final Color badgeFg;

    if (stageIndex < currentStage) {
      leadingIcon = const Icon(Icons.check_circle, color: _primary, size: 28);
      badge = 'Done';
      badgeBg = _chipBg;
      badgeFg = _primary;
    } else if (stageIndex == currentStage) {
      leadingIcon = const Icon(Icons.bolt_rounded, color: _gold, size: 28);
      badge = 'Active';
      badgeBg = _gold.withValues(alpha: 0.2);
      badgeFg = const Color(0xFF7A6000);
    } else {
      leadingIcon = const Icon(Icons.lock_rounded, color: Color(0xFF9CA3AF), size: 28);
      badge = 'Locked';
      badgeBg = const Color(0xFFF3F4F6);
      badgeFg = const Color(0xFF6B7280);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leadingIcon,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeFg,
            ),
          ),
        ),
      ],
    );
  }

  Widget _accountCard({
    required UserModel student,
    required String userId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Info',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primary,
            ),
          ),
          const SizedBox(height: 14),
          _accountFieldRow(
            icon: Icons.badge_outlined,
            label: 'Student ID',
            child: Text(
              student.studentId.isNotEmpty ? student.studentId : 'N/A',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _accountFieldRow(
            icon: Icons.person_outline_rounded,
            label: 'Full name',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _accountFieldRow(
            icon: Icons.link_rounded,
            label: 'GitHub',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _githubController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: 'https://github.com/...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Open link',
                  onPressed: _githubController.text.trim().isEmpty
                      ? null
                      : () => openGithub(_githubController.text.trim()),
                  icon: const Icon(Icons.open_in_new_rounded, color: _primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving
                  ? null
                  : () => _saveProfile(
                        userId: userId,
                        currentName: student.name,
                        currentGithub: student.githubLink,
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountFieldRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: _primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _skillsCard() {
    const skills = [
      'Flutter',
      'Dart',
      'Firebase',
      'Firestore',
      'GitHub',
      'API Calls',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skills',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _primary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills
                .map(
                  (s) => Chip(
                    label: Text(s),
                    backgroundColor: _chipBg,
                    labelStyle: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
