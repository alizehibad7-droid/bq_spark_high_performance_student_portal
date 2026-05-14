import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/task_model.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confirmation_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _filter = 'Pending';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final taskProvider = context.read<TaskProvider>();
      final userId = authProvider.currentUser?.uid;
      if (userId != null &&
          taskProvider.tasks.isEmpty &&
          !taskProvider.isLoading) {
        taskProvider.watchTasksForUser(userId);
      }
    });
  }

  Future<void> _handleSubmission({
    required BuildContext context,
    required String userId,
    required TaskModel task,
  }) async {
    final String link = task.submissionLink.trim();

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No submission link provided for this task.')),
      );
      return;
    }

    // 1. Parse and try to launch URL
    Uri? uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://$link');
    }

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid submission link.')),
      );
      return;
    }

    try {
      // 2. Launch Google Form
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) throw 'Could not launch URL';

      // 3. Show a professional confirmation dialog after returning to app
      if (!mounted) return;
      final bool? hasSubmitted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Submission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_turned_in_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Did you finish submitting your assignment on the Google Form for "${task.title}"?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not Yet', style: TextStyle(color: AppColors.textGray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Yes, Mark as Done'),
            ),
          ],
        ),
      );

      if (hasSubmitted == true) {
        // 4. Mark as completed in Firebase
        if (!mounted) return;
        await context.read<TaskProvider>().markTaskComplete(
          userId: userId,
          task: task,
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening form: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.uid;

    final filteredTasks = taskProvider.tasks.where((task) {
      final isCompleted = taskProvider.completedTaskIds.contains(task.id);
      return _filter == 'Completed' ? isCompleted : !isCompleted;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tasks"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (taskProvider.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                taskProvider.error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 8),
          Expanded(
            child: taskProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filter == 'Pending' ? Icons.task_alt : Icons.done_all,
                          size: 64,
                          color: AppColors.textGray.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'Pending'
                              ? 'All caught up! No pending tasks.'
                              : 'No completed tasks yet.',
                          style: const TextStyle(color: AppColors.textGray),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTasks.length,
                    itemBuilder: (_, index) {
                      final task = filteredTasks[index];
                      final completed = taskProvider.completedTaskIds.contains(
                        task.id,
                      );
                      return _taskCard(
                        context: context,
                        task: task,
                        completed: completed,
                        isCompleting: taskProvider.completingTaskIds.contains(
                          task.id,
                        ),
                        userId: userId,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('Pending'),
          const SizedBox(width: 8),
          _filterChip('Completed'),
        ],
      ),
    );
  }

  Widget _filterChip(String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(value),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.secondary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textDark,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.cardColor,
    );
  }

  Widget _taskCard({
    required BuildContext context,
    required TaskModel task,
    required bool completed,
    required bool isCompleting,
    required String? userId,
  }) {
    final due = task.dueDate == null
        ? 'No due date'
        : DateFormat('dd MMM yyyy').format(task.dueDate!);

    final bool hasLink = task.submissionLink.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category/Points
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasLink ? Icons.assignment_outlined : Icons.task_alt,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasLink ? 'Assignment' : 'Task',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${task.points} Points',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: const TextStyle(color: AppColors.textGray, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Footer: Date & Action
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textGray.withOpacity(0.6)),
                const SizedBox(width: 6),
                Text(
                  'Due: $due',
                  style: TextStyle(fontSize: 12, color: AppColors.textGray.withOpacity(0.8)),
                ),
                const Spacer(),
                
                // Action Button
                isCompleting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : completed
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Done', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: userId == null 
                          ? null 
                          : () {
                              if (hasLink) {
                                _handleSubmission(context: context, userId: userId, task: task);
                              } else {
                                // Fallback to manual complete if no link
                                context.read<TaskProvider>().markTaskComplete(userId: userId, task: task);
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          hasLink ? 'Submit Assignment' : 'Mark Done',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
