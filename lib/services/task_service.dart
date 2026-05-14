import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TaskModel>> streamTasks() {
    return _db.collection('tasks').orderBy('dueDate').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required int points,
    required String createdBy,
    String submissionLink = '',
  }) async {
    debugPrint('Adding task: $title');
    await _db.collection('tasks').add({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'points': points,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'submissionLink': submissionLink,
    });
  }

  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  Stream<Set<String>> streamCompletedTaskIdsForUser(String studentUid) {
    return _db
        .collection('taskCompletions')
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => (doc.data()['taskId'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();
        });
  }

  Future<void> completeTaskAndAddPoints({
    required String studentUid,
    required String taskId,
    required int earnedPoints,
  }) async {
    // IMPORTANT: Make sure Firestore rules allow:
    // users to write to 'taskCompletions' collection
    // users to update their own 'users' document
    // Go to Firebase Console → Firestore → Rules
    // and ensure these rules are set:
    //
    // match /taskCompletions/{docId} {
    //   allow read, write: if request.auth != null;
    // }
    // match /users/{userId} {
    //   allow read: if request.auth != null;
    //   allow write: if request.auth.uid == userId;
    // }
    final safeDocId = '${studentUid}_$taskId'
        .replaceAll('/', '_')
        .replaceAll('.', '_');
    final completionRef = _db.collection('taskCompletions').doc(safeDocId);
    final userRef = _db.collection('users').doc(studentUid);

    try {
      await _db.runTransaction((tx) async {
        final completionSnap = await tx.get(completionRef);
        if (completionSnap.exists) {
          throw Exception('Task already completed');
        }

        final userSnap = await tx.get(userRef);
        final currentPoints = ((userSnap.data()?['totalPoints'] ?? 0) as num)
            .toInt();

        tx.set(completionRef, {
          'userId': studentUid,
          'studentUid': studentUid,
          'taskId': taskId,
          'completedAt': FieldValue.serverTimestamp(),
        });

        tx.set(userRef, {
          'totalPoints': currentPoints + earnedPoints,
        }, SetOptions(merge: true));
      });
      debugPrint(
        'Task completion success: user=$studentUid task=$taskId points=$earnedPoints',
      );
    } catch (e, stack) {
      debugPrint('Task completion error: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Stream<int> streamTaskCount() {
    return _db.collection('tasks').snapshots().map((snapshot) => snapshot.size);
  }

  Stream<int> streamCompletedRecordsCount() {
    return _db
        .collection('taskCompletions')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
