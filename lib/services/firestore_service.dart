import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserModel?> streamUserById(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<List<UserModel>> streamLeaderboardUsers() {
    return _db
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .where((user) => user.role == 'student')
              .toList();
        });
  }

  Stream<List<UserModel>> streamAllStudents() {
    // If students still don't load, go to:
    // Firebase Console → Firestore → Rules
    // Set rules to allow authenticated reads:
    // match /users/{uid} {
    //   allow read: if request.auth != null;
    //   allow write: if request.auth != null;
    // }
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) {
          debugPrint('Students fetched: ${snapshot.docs.length}');
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();
        })
        .handleError((e) {
          debugPrint('Stream error: $e');
        });
  }

  Future<void> updateUserStage({
    required String userId,
    required int currentStage,
  }) async {
    await _db.collection('users').doc(userId).update({
      'currentStage': currentStage.clamp(1, 4),
    });
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String githubLink,
  }) async {
    await _db.collection('users').doc(userId).set({
      'name': name.trim(),
      'githubLink': githubLink.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> registerStudentProfile({
    required String userId,
    required String studentId,
    required String name,
    required String email,
    String role = 'student',
  }) async {
    await _db.collection('users').doc(userId).set({
      'studentId': studentId,
      'studentIdNormalized': studentId.trim().toLowerCase(),
      'name': name,
      'email': email,
      'role': role,
      'githubLink': '',
      'totalPoints': 0,
      'currentStage': 1,
      'profileImage': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> streamStudentCount() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<List<String>> fetchRecentActivities() async {
    final activities = <String>[];

    final recentTasks = await _db
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    for (final doc in recentTasks.docs) {
      final title = (doc.data()['title'] ?? 'Untitled Task').toString();
      activities.add('Task added: $title');
    }

    final recentResources = await _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    for (final doc in recentResources.docs) {
      final title = (doc.data()['title'] ?? 'Untitled Resource').toString();
      activities.add('Resource added: $title');
    }

    final recentCompletions = await _db
        .collection('task_completions')
        .orderBy('completedAt', descending: true)
        .limit(3)
        .get();
    for (final doc in recentCompletions.docs) {
      final taskId = (doc.data()['taskId'] ?? '').toString();
      final studentUid = (doc.data()['studentUid'] ?? '').toString();
      activities.add('Task completion: $taskId by $studentUid');
    }

    if (activities.isEmpty) {
      return ['No recent activity found.'];
    }
    return activities.take(8).toList();
  }
}
