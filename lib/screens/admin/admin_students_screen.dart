import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'admin_student_detail_screen.dart';

class AdminStudentsScreen extends StatelessWidget {
  const AdminStudentsScreen({super.key});

  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _goldAccent = Color(0xFFB8A030);
  static const Color _bg = Color(0xFFF5F5F5);

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'NA';
    return trimmed.length < 2
        ? trimmed.toUpperCase()
        : trimmed.substring(0, 2).toUpperCase();
  }

  Future<void> _deleteStudent(BuildContext context, UserModel student) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: Text(
          'Delete "${student.name}" (${student.studentId})?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete from Firestore only
      await FirebaseFirestore.instance.collection('users').doc(student.id).delete();

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

  Future<void> _showDeleteDialog(BuildContext context, UserModel student) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: Text(
          'Are you sure you want to delete "${student.name}" (${student.studentId})?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteStudent(context, student);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, UserModel student) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditStudentSheet(student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<FirestoreService>();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('View Students'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: service.streamAllStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }
          final students = snapshot.data ?? <UserModel>[];
          if (students.isEmpty) {
            return const Center(child: Text('No students registered yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(
                color: Colors.white,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminStudentDetailScreen(student: s),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _primaryGreen,
                              child: Text(
                                _initials(s.name),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(s.studentId),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _goldAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Stage ${s.currentStage}/4',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('${s.totalPoints} pts'),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: Color(0xFF1A5C35),
                              ),
                              onPressed: () => _showEditDialog(context, s),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteStudent(context, s),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<UserModel>> debugStreamStudents() async* {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      debugPrint('Total docs in users: ${snap.docs.length}');
      for (final doc in snap.docs) {
        debugPrint('Doc: ${doc.id} -> ${doc.data()}');
      }
      final all = snap.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .toList();
      yield all;
    } catch (e) {
      debugPrint('Students load error: $e');
      yield <UserModel>[];
    }
  }
}

class EditStudentSheet extends StatefulWidget {
  const EditStudentSheet({super.key, required this.student});

  final UserModel student;

  @override
  State<EditStudentSheet> createState() => _EditStudentSheetState();
}

class _EditStudentSheetState extends State<EditStudentSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _studentIdController;
  late final TextEditingController _githubController;
  late int _selectedStage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _studentIdController = TextEditingController(text: widget.student.studentId);
    _githubController = TextEditingController(text: widget.student.githubLink);
    _selectedStage = widget.student.currentStage.clamp(1, 4);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _saveEdits() async {
    await FirebaseFirestore.instance.collection('users').doc(widget.student.id).update({
      'name': _nameController.text.trim(),
      'currentStage': _selectedStage,
      'githubLink': _githubController.text.trim(),
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Edit Student',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1A5C35),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _studentIdController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              helperText: 'Student ID cannot be changed — it is the login',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _selectedStage,
            decoration: const InputDecoration(labelText: 'Stage'),
            items: const [1, 2, 3, 4]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                .toList(),
            onChanged: (value) => setState(() => _selectedStage = value ?? 1),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _githubController,
            decoration: const InputDecoration(labelText: 'GitHub Link'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C35)),
              onPressed: _saveEdits,
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
