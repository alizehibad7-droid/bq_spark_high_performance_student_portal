import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/resource_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/resource_service.dart';
import '../services/task_service.dart';
import '../widgets/confirmation_dialog.dart';
import 'role_selection_screen.dart';
import 'admin/admin_register_student_screen.dart';
import 'admin/admin_student_detail_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _pageBg = Color(0xFFF4F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textMuted = Color(0xFF6B7280);

  int _selectedIndex = 0;

  static const List<String> _titles = [
    'Dashboard',
    'Tasks',
    'Students',
    'Resources',
    'Settings',
  ];

  Future<void> _logout() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
      (route) => false,
    );
  }

  void _openNotifyBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NotifyBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_titles[_selectedIndex]),
        automaticallyImplyLeading: canPop,
        leading: null,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            alignment: Alignment.center,
            child: const Text(
              'AD',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _AdminDashboardTab(
            onNavigateTab: (index) => setState(() => _selectedIndex = index),
            onOpenNotifySheet: _openNotifyBottomSheet,
          ),
          const _AdminTasksTab(),
          const _AdminStudentsTab(),
          const _AdminResourcesTab(),
          _AdminSettingsTab(onLogout: _logout),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: _textMuted,
        backgroundColor: _cardBg,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Resources',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab({
    required this.onNavigateTab,
    required this.onOpenNotifySheet,
  });

  final ValueChanged<int> onNavigateTab;
  final VoidCallback onOpenNotifySheet;

  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _lightGreen = Color(0xFFE8F4EE);
  static const Color _gold = Color(0xFFB8A030);
  static const Color _goldLight = Color(0xFFFFF8E1);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final taskService = context.read<TaskService>();
    final resourceService = context.read<ResourceService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5C35), Color(0xFF2E7D52)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning, Admin 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BQ Spark High Performance Portal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    StreamBuilder<int>(
                      stream: firestoreService.streamStudentCount(),
                      builder: (context, snapshot) {
                        final value = snapshot.data ?? 0;
                        return _headerChip('$value Students');
                      },
                    ),
                    _headerChip('Active Program'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryGreen,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _statCard(
                context,
                icon: Icons.groups_rounded,
                iconBg: _lightGreen,
                iconColor: _primaryGreen,
                label: 'Total Students',
                stream: firestoreService.streamStudentCount(),
              ),
              _statCard(
                context,
                icon: Icons.assignment_rounded,
                iconBg: _lightGreen,
                iconColor: _primaryGreen,
                label: 'Total Tasks',
                stream: taskService.streamTaskCount(),
              ),
              _statCard(
                context,
                icon: Icons.check_circle_rounded,
                iconBg: _lightGreen,
                iconColor: _primaryGreen,
                label: 'Completed',
                stream: taskService.streamCompletedRecordsCount(),
              ),
              _statCard(
                context,
                icon: Icons.menu_book_rounded,
                iconBg: _goldLight,
                iconColor: _gold,
                label: 'Resources',
                stream: resourceService.streamResourceCount(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Task Completion Rate',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider),
            ),
            child: StreamBuilder<int>(
              stream: taskService.streamTaskCount(),
              builder: (context, totalSnap) {
                if (totalSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }
                if (totalSnap.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading stats',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                return StreamBuilder<int>(
                  stream: taskService.streamCompletedRecordsCount(),
                  builder: (context, completedSnap) {
                    if (completedSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _primaryGreen),
                      );
                    }
                    if (completedSnap.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading stats',
                          style: TextStyle(color: _textMuted),
                        ),
                      );
                    }
                    final total = totalSnap.data ?? 0;
                    final completed = completedSnap.data ?? 0;
                    final ratio = total == 0
                        ? 0.0
                        : (completed / total).clamp(0.0, 1.0);
                    return Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Completed Tasks',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$completed / $total',
                              style: const TextStyle(color: _textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: ratio,
                            backgroundColor: _divider,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _gold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${(ratio * 100).toStringAsFixed(1)}% of all tasks completed',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickActionChip(
                  label: 'Add Task',
                  icon: Icons.task_alt_rounded,
                  onTap: () => onNavigateTab(1),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  label: 'Add Student',
                  icon: Icons.groups_rounded,
                  onTap: () => onNavigateTab(2),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  label: 'Add Resource',
                  icon: Icons.menu_book_rounded,
                  onTap: () => onNavigateTab(3),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  label: 'Notify All',
                  icon: Icons.notifications_active_rounded,
                  onTap: onOpenNotifySheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _divider),
            ),
            child: FutureBuilder<List<String>>(
              future: firestoreService.fetchRecentActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load activity',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                final activities = snapshot.data ?? <String>[];
                if (activities.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent activity yet',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                return Column(
                  children: activities.take(5).map((activity) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        activity,
                        style: const TextStyle(fontSize: 12, color: _textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Stream<int> stream,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
      ),
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final value = snapshot.data ?? 0;
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _primaryGreen,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickActionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: _primaryGreen),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: _textDark)),
          ],
        ),
      ),
    );
  }
}

class _AdminTasksTab extends StatefulWidget {
  const _AdminTasksTab();

  @override
  State<_AdminTasksTab> createState() => _AdminTasksTabState();
}

class _AdminTasksTabState extends State<_AdminTasksTab> {
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _lightGreen = Color(0xFFE8F4EE);
  static const Color _gold = Color(0xFFB8A030);
  static const Color _goldLight = Color(0xFFFFF8E1);
  static const Color _pageBg = Color(0xFFF4F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  bool _showAddForm = false;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: now,
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final taskService = context.read<TaskService>();
      final uid = context.read<AuthService>().currentUser?.uid ?? 'admin';
      await taskService.addTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate!,
        points: int.parse(_pointsCtrl.text.trim()),
        createdBy: uid,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _descCtrl.clear();
      _pointsCtrl.clear();
      setState(() => _dueDate = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task added successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add task: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete this task?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await context.read<TaskService>().deleteTask(taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete task: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Tasks'),
                  selected: !_showAddForm,
                  onSelected: (_) => setState(() => _showAddForm = false),
                  selectedColor: _lightGreen,
                  labelStyle: TextStyle(
                    color: !_showAddForm ? _primaryGreen : _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Add New Task'),
                  selected: _showAddForm,
                  onSelected: (_) => setState(() => _showAddForm = true),
                  selectedColor: _lightGreen,
                  labelStyle: TextStyle(
                    color: _showAddForm ? _primaryGreen : _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _showAddForm ? _buildAddForm() : _buildTaskList()),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: context.read<TaskService>().streamTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load tasks',
              style: TextStyle(color: _textMuted),
            ),
          );
        }
        final tasks = snapshot.data ?? <TaskModel>[];
        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No tasks available',
              style: TextStyle(color: _textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final dueText = task.dueDate == null
                ? 'No due date'
                : DateFormat('dd MMM yyyy').format(task.dueDate!);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _goldLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '+${task.points} pts',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 12,
                                color: _textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dueText,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: _divider, height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 15,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '0 completions',
                        style: TextStyle(fontSize: 11, color: _textMuted),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _deleteTask(task.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: _adminInputDecoration('Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: _adminInputDecoration('Description'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: _adminInputDecoration('Points'),
                validator: (v) {
                  final points = int.tryParse(v ?? '');
                  return (points == null || points <= 0)
                      ? 'Enter valid points'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _adminInputDecoration('Due Date'),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: _primaryGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dueDate == null
                            ? 'Pick due date'
                            : DateFormat('dd MMM yyyy').format(_dueDate!),
                        style: const TextStyle(color: _textDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: _primaryButtonStyle(),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminStudentsTab extends StatelessWidget {
  const _AdminStudentsTab();

  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _lightGreen = Color(0xFFE8F4EE);
  static const Color _gold = Color(0xFFB8A030);
  static const Color _pageBg = Color(0xFFF4F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirestoreService>();
    return Container(
      color: _pageBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'HP Students',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminRegisterStudentScreen(),
                      ),
                    );
                  },
                  style: _primaryButtonStyle(),
                  child: const Text('Register New +'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: service.streamAllStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load students',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                final students = snapshot.data ?? <UserModel>[];
                if (students.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final initials = _initials(student.name);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminStudentDetailScreen(student: student),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _divider),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: _primaryGreen,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          student.name.isEmpty
                                              ? 'Student'
                                              : student.name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _textDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _lightGreen,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Stage ${student.currentStage}/4',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _primaryGreen,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    student.studentId,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 12,
                                        color: _gold,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${student.totalPoints} pts',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _gold,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _deleteStudent(context, student),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent(
      BuildContext context, UserModel student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Student'),
        content: Text(
          'Delete "${student.name}"?\n'
          'Student ID: ${student.studentId}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(student.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'NA';
    if (trimmed.length < 2) return trimmed.toUpperCase();
    return trimmed.substring(0, 2).toUpperCase();
  }
}

class _AdminResourcesTab extends StatefulWidget {
  const _AdminResourcesTab();

  @override
  State<_AdminResourcesTab> createState() => _AdminResourcesTabState();
}

class _AdminResourcesTabState extends State<_AdminResourcesTab> {
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _lightGreen = Color(0xFFE8F4EE);
  static const Color _pageBg = Color(0xFFF4F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  bool _showAddForm = false;
  String _selectedCategory = 'All';
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  String _category = 'Notes';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final resourceService = context.read<ResourceService>();
      await resourceService.addResource(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        link: _linkCtrl.text.trim(),
        category: _category,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _descCtrl.clear();
      _linkCtrl.clear();
      setState(() => _category = 'Notes');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add resource: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Resource',
      message: 'Are you sure you want to delete this resource?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await context.read<ResourceService>().deleteResource(id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resource deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete resource: $e')));
    }
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open resource')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _pageBg,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All Resources'),
                  selected: !_showAddForm,
                  onSelected: (_) => setState(() => _showAddForm = false),
                  selectedColor: _lightGreen,
                  labelStyle: TextStyle(
                    color: !_showAddForm ? _primaryGreen : _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Add New'),
                  selected: _showAddForm,
                  onSelected: (_) => setState(() => _showAddForm = true),
                  selectedColor: _lightGreen,
                  labelStyle: TextStyle(
                    color: _showAddForm ? _primaryGreen : _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!_showAddForm)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', 'Notes', 'Videos', 'Interview Prep', 'Tools']
                    .map((category) {
                      final selected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                          selectedColor: _primaryGreen,
                          backgroundColor: _cardBg,
                          side: const BorderSide(color: _divider),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : _textMuted,
                            fontSize: 11,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _showAddForm ? _buildAddForm() : _buildResourceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceList() {
    return StreamBuilder<List<ResourceModel>>(
      stream: context.read<ResourceService>().streamResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryGreen),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Failed to load resources',
              style: TextStyle(color: _textMuted),
            ),
          );
        }
        final all = snapshot.data ?? <ResourceModel>[];
        final resources = _selectedCategory == 'All'
            ? all
            : all.where((item) => item.category == _selectedCategory).toList();
        if (resources.isEmpty) {
          return const Center(
            child: Text(
              'No resources found',
              style: TextStyle(color: _textMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final item = resources[index];
            final categoryStyle = _categoryStyle(item.category);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: categoryStyle.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryStyle.icon,
                      color: categoryStyle.iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _lightGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  color: _primaryGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _openLink(item.link),
                              icon: const Icon(
                                Icons.open_in_new,
                                color: _primaryGreen,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _delete(item.id),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: _adminInputDecoration('Title'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: _adminInputDecoration('Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkCtrl,
                decoration: _adminInputDecoration('Link'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _adminInputDecoration('Category'),
                items: const [
                  DropdownMenuItem(value: 'Notes', child: Text('Notes')),
                  DropdownMenuItem(value: 'Videos', child: Text('Videos')),
                  DropdownMenuItem(
                    value: 'Interview Prep',
                    child: Text('Interview Prep'),
                  ),
                  DropdownMenuItem(value: 'Tools', child: Text('Tools')),
                ],
                onChanged: (value) =>
                    setState(() => _category = value ?? 'Notes'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: _primaryButtonStyle(),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CategoryStyle _categoryStyle(String category) {
    switch (category) {
      case 'Videos':
        return const _CategoryStyle(
          bg: Color(0xFFFFF8E1),
          iconColor: Color(0xFFB8A030),
          icon: Icons.play_circle,
        );
      case 'Interview Prep':
        return const _CategoryStyle(
          bg: Color(0xFFEDE7F6),
          iconColor: Color(0xFF7B1FA2),
          icon: Icons.psychology,
        );
      case 'Tools':
        return const _CategoryStyle(
          bg: Color(0xFFE3F2FD),
          iconColor: Color(0xFF1565C0),
          icon: Icons.build,
        );
      case 'Notes':
      default:
        return const _CategoryStyle(
          bg: Color(0xFFE8F4EE),
          iconColor: Color(0xFF1A5C35),
          icon: Icons.menu_book_rounded,
        );
    }
  }
}

class _CategoryStyle {
  const _CategoryStyle({
    required this.bg,
    required this.iconColor,
    required this.icon,
  });

  final Color bg;
  final Color iconColor;
  final IconData icon;
}

class _AdminSettingsTab extends StatefulWidget {
  const _AdminSettingsTab({required this.onLogout});

  final VoidCallback onLogout;

  @override
  State<_AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<_AdminSettingsTab> {
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _lightGreen = Color(0xFFE8F4EE);
  static const Color _pageBg = Color(0xFFF4F6F8);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _divider = Color(0xFFE5E7EB);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final sentBy = context.read<AuthService>().currentUser?.uid ?? 'admin';
      await context.read<NotificationService>().addNotification(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        sentBy: sentBy,
      );
      _titleCtrl.clear();
      _bodyCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.read<NotificationService>();
    return Container(
      color: _pageBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active, color: _primaryGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Send Notification to All Students',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _adminInputDecoration('Notification Title'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyCtrl,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _adminInputDecoration('Message'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _sending ? null : _send,
                        style: _primaryButtonStyle(),
                        child: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send to All Students'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Recently Sent',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: notificationService.streamRecentNotifications(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primaryGreen),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load notifications',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recent notifications',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final sentAt = data['sentAt'] as Timestamp?;
                    final dateText = sentAt == null
                        ? '-'
                        : DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(sentAt.toDate());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _lightGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: _primaryGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['title'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (data['body'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _textMuted,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateText,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _divider),
              ),
              child: Column(
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.admin_panel_settings,
                      color: _primaryGreen,
                    ),
                    title: Text(
                      'Admin Account',
                      style: TextStyle(color: _textDark),
                    ),
                    subtitle: Text(
                      'Logged in as admin',
                      style: TextStyle(color: _textMuted),
                    ),
                  ),
                  const Divider(color: _divider),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: widget.onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifyBottomSheet extends StatefulWidget {
  const _NotifyBottomSheet();

  @override
  State<_NotifyBottomSheet> createState() => _NotifyBottomSheetState();
}

class _NotifyBottomSheetState extends State<_NotifyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final sentBy = context.read<AuthService>().currentUser?.uid ?? 'admin';
      await context.read<NotificationService>().addNotification(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        sentBy: sentBy,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send Notification',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: _adminInputDecoration('Notification Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: _adminInputDecoration('Message'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: _primaryButtonStyle(),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Send to All Students'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _adminInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF4F6F8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A5C35)),
    ),
    labelStyle: const TextStyle(color: Color(0xFF1A5C35)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

ButtonStyle _primaryButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF1A5C35),
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
