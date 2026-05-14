import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final int points;
  final String submissionLink;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.points,
    this.submissionLink = '',
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    final dynamic rawPoints = data['points'];
    final int parsedPoints = rawPoints is int
        ? rawPoints
        : int.tryParse(rawPoints?.toString() ?? '') ?? 0;

    final dynamic rawDueDate = data['dueDate'];
    DateTime? parsedDueDate;
    if (rawDueDate is Timestamp) {
      parsedDueDate = rawDueDate.toDate();
    } else if (rawDueDate is DateTime) {
      parsedDueDate = rawDueDate;
    } else if (rawDueDate is String) {
      parsedDueDate = DateTime.tryParse(rawDueDate);
    }

    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: parsedDueDate,
      points: parsedPoints,
      submissionLink: data['submissionLink'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate!),
      'points': points,
      'submissionLink': submissionLink,
    };
  }
}
