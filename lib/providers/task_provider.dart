import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/task_model.dart';import '../services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._taskService);

  final TaskService _taskService;

  List<TaskModel> _tasks = <TaskModel>[];
  Set<String> _completedTaskIds = <String>{};
  Set<String> _completingTaskIds = <String>{};
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TaskModel>>? _taskSub;
  StreamSubscription<Set<String>>? _completionSub;

  List<TaskModel> get tasks => _tasks;
  Set<String> get completedTaskIds => _completedTaskIds;
  Set<String> get completingTaskIds => _completingTaskIds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> watchTasksForUser(String userId) async {
    _isLoading = true;
    _error = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) notifyListeners();
    });

    try {
      await _taskSub?.cancel();
      await _completionSub?.cancel();

      _taskSub = _taskService.streamTasks().listen((items) {
        _tasks = items;
        _isLoading = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) notifyListeners();
        });
      });

      _completionSub = _taskService
          .streamCompletedTaskIdsForUser(userId)
          .listen((ids) {
            _completedTaskIds = ids;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (hasListeners) notifyListeners();
            });
          });
    } catch (_) {
      _error = 'Unable to load tasks right now.';
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    }
  }

  Future<void> markTaskComplete({
    required String userId,
    required TaskModel task,
  }) async {
    if (_completingTaskIds.contains(task.id)) return;
    _completingTaskIds = <String>{..._completingTaskIds, task.id};
    _error = null;
    notifyListeners();
    try {
      await _taskService.completeTaskAndAddPoints(
        studentUid: userId,
        taskId: task.id,
        earnedPoints: task.points,
      );
    } catch (_) {
      _error = 'Could not mark task complete. Please try again.';
      rethrow;
    } finally {
      _completingTaskIds = <String>{..._completingTaskIds}..remove(task.id);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _taskSub?.cancel();
    _completionSub?.cancel();
    super.dispose();
  }
}
