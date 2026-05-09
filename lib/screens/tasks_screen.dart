import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final userId = authProvider.currentUser?.uid;
    if (userId != null &&
        taskProvider.tasks.isEmpty &&
        !taskProvider.isLoading) {
      taskProvider.watchTasksForUser(userId);
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
                    child: Text(
                      _filter == 'Pending'
                          ? 'No pending tasks.'
                          : 'No completed tasks yet.',
                      style: const TextStyle(color: AppColors.textGray),
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
                        onComplete: userId == null || completed
                            ? null
                            : () async {
                                await context
                                    .read<TaskProvider>()
                                    .markTaskComplete(
                                      userId: userId,
                                      task: task,
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
      ),
      backgroundColor: AppColors.cardColor,
    );
  }

  Widget _taskCard({
    required BuildContext context,
    required TaskModel task,
    required bool completed,
    required bool isCompleting,
    required Future<void> Function()? onComplete,
  }) {
    final due = task.dueDate == null
        ? 'No due date'
        : DateFormat('dd MMM yyyy').format(task.dueDate!);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${task.points} pts',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            task.description,
            style: const TextStyle(color: AppColors.textGray),
          ),
          const SizedBox(height: 8),
          Text(
            'Due: $due',
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: completed
                  ? null
                  : isCompleting
                  ? null
                  : () async {
                      if (onComplete != null) {
                        try {
                          final alreadyCompleted = context
                              .read<TaskProvider>()
                              .completedTaskIds
                              .contains(task.id);
                          if (alreadyCompleted) {
                            debugPrint(
                              'Task completion skipped, already completed: ${task.id}',
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Already completed'),
                              ),
                            );
                            return;
                          }
                          final confirm = await showConfirmationDialog(
                            context,
                            title: 'Mark Task Complete',
                            message:
                                'Are you sure you want to mark this task as completed?',
                            confirmLabel: 'Mark Complete',
                          );
                          if (!confirm) return;
                          await onComplete();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task marked as completed.'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not complete task: $e'),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: completed
                    ? AppColors.textGray
                    : AppColors.primary,
              ),
              child: isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(completed ? 'Completed' : 'Mark Complete'),
            ),
          ),
        ],
      ),
    );
  }
}
