class UserModel {
  final String id;
  final String studentId;
  final String name;
  final String email;
  final String role;
  final String githubLink;
  final int totalPoints;
  final int currentStage;

  UserModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.role,
    required this.githubLink,
    required this.totalPoints,
    required this.currentStage,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    final rawPoints = data['totalPoints'];
    final parsedPoints = rawPoints is int
        ? rawPoints
        : int.tryParse(rawPoints?.toString() ?? '') ?? 0;
    final rawStage = data['currentStage'];
    final parsedStage = rawStage is int
        ? rawStage
        : int.tryParse(rawStage?.toString() ?? '') ?? 1;

    return UserModel(
      id: id,
      studentId: data['studentId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      githubLink: data['githubLink'] ?? '',
      totalPoints: parsedPoints,
      currentStage: parsedStage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'email': email,
      'role': role,
      'githubLink': githubLink,
      'totalPoints': totalPoints,
      'currentStage': currentStage,
    };
  }
}