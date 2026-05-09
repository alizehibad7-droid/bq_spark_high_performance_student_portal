import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class AdminStudentDetailScreen extends StatefulWidget {
  const AdminStudentDetailScreen({super.key, required this.student});

  final UserModel student;

  @override
  State<AdminStudentDetailScreen> createState() => _AdminStudentDetailScreenState();
}

class _AdminStudentDetailScreenState extends State<AdminStudentDetailScreen> {
  late int _stage;
  bool _updating = false;
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _bg = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _stage = widget.student.currentStage.clamp(1, 4);
  }

  Future<void> _updateStage() async {
    setState(() => _updating = true);
    try {
      await context.read<FirestoreService>().updateUserStage(
            userId: widget.student.id,
            currentStage: _stage,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stage updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stage: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openGithub(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Student Detail'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name: ${s.name}'),
                  const SizedBox(height: 8),
                  Text('Student ID: ${s.studentId}'),
                  const SizedBox(height: 8),
                  Text('Email: ${s.email}'),
                  const SizedBox(height: 8),
                  Text('Total Points: ${s.totalPoints}'),
                  const SizedBox(height: 12),
                  const Text('Current Stage'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _stage / 4,
                    backgroundColor: Colors.grey.shade200,
                    color: _primaryGreen,
                    minHeight: 10,
                  ),
                  const SizedBox(height: 8),
                  Text('Stage $_stage/4'),
                ],
              ),
            ),
          ),
          if (s.githubLink.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              child: ListTile(
                title: const Text('GitHub Link'),
                subtitle: Text(s.githubLink),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openGithub(s.githubLink),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Stage',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _stage,
                    items: const [1, 2, 3, 4]
                        .map(
                          (v) => DropdownMenuItem(value: v, child: Text('$v')),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _stage = value ?? 1),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _updating ? null : _updateStage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _updating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Stage'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
