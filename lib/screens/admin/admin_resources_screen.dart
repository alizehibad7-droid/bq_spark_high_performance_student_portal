import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/resource_model.dart';
import '../../services/resource_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirmation_dialog.dart';

class AdminResourcesScreen extends StatefulWidget {
  const AdminResourcesScreen({super.key});

  @override
  State<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends State<AdminResourcesScreen> {
  static const Color _primaryGreen = Color(0xFF1A5C35);
  static const Color _goldAccent = Color(0xFFB8A030);
  static const Color _bg = Color(0xFFF5F5F5);

  Future<void> _openLink(String rawUrl) async {
    String url = rawUrl.trim();
    if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://')) {
      url = 'https://$url';
    }

    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No link available')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Admin resource opened: $url');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot open: $url')));
        debugPrint('Admin resource cannot launch: $url');
      }
    } catch (e, stack) {
      debugPrint('Admin resource link open error: $e');
      debugPrint('Admin resource link open stack: $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot open: $url')));
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Resource',
      message: 'Are you sure you want to delete this resource?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      await _delete(id);
    }
  }

  Future<void> _delete(String id) async {
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

  @override
  Widget build(BuildContext context) {
    final service = context.read<ResourceService>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Resources'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'All Resources'),
              Tab(text: 'Add Resource'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StreamBuilder<List<ResourceModel>>(
              stream: service.streamResources(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final resources = snapshot.data ?? <ResourceModel>[];
                if (resources.isEmpty) {
                  return const Center(child: Text('No resources found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final item = resources[index];
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        onTap: () => _openLink(item.link),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          item.description,
                          style: const TextStyle(color: AppColors.textGray),
                        ),
                        leading: Chip(
                          backgroundColor: _goldAccent,
                          label: Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(item.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const _AddResourceForm(),
          ],
        ),
      ),
    );
  }
}

class _AddResourceForm extends StatefulWidget {
  const _AddResourceForm();

  @override
  State<_AddResourceForm> createState() => _AddResourceFormState();
}

class _AddResourceFormState extends State<_AddResourceForm> {
  String _selectedCategory = 'Notes';
  String? _pickedFileName;
  Uint8List? _pickedFileBytes;
  bool _isUploading = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if ((file.size) > 10 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large. Max 10MB.')),
        );
        return;
      }
      setState(() {
        _pickedFileName = file.name;
        _pickedFileBytes = file.bytes;
      });
    }
  }

  Future<void> _submitResource() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    if (_selectedCategory == 'Notes' &&
        _pickedFileBytes == null &&
        _linkCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a PDF or enter a link')),
      );
      return;
    }

    if (_selectedCategory != 'Notes' && _linkCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link is required')));
      return;
    }

    setState(() => _isUploading = true);
    try {
      String finalLink = _linkCtrl.text.trim();

      if (_pickedFileBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('resources/notes')
            .child('${DateTime.now().millisecondsSinceEpoch}_$_pickedFileName');

        final task = ref.putData(
          _pickedFileBytes!,
          SettableMetadata(contentType: 'application/pdf'),
        );
        final snap = await task;
        finalLink = await snap.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('resources').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'link': finalLink,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource added successfully')),
        );
        _titleCtrl.clear();
        _descCtrl.clear();
        _linkCtrl.clear();
        setState(() {
          _selectedCategory = 'Notes';
          _pickedFileName = null;
          _pickedFileBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              'Notes',
              'Videos',
              'Interview Prep',
              'Tools',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedCategory = val ?? 'Notes';
                _pickedFileName = null;
                _pickedFileBytes = null;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _linkCtrl,
            decoration: InputDecoration(
              labelText: _selectedCategory == 'Notes'
                  ? 'Link (optional if uploading PDF)'
                  : 'Link',
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedCategory == 'Notes') ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text(
                  'Or upload a PDF file directly:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickPdf,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1A5C35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFF1A5C35),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pickedFileName ?? 'Tap to select PDF',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _pickedFileName != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: const Color(0xFF1A5C35),
                            ),
                          ),
                          if (_pickedFileName == null)
                            const Text(
                              'PDF files only • Max 10MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_pickedFileName != null)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1A5C35),
                      ),
                    if (_pickedFileName == null)
                      const Icon(
                        Icons.upload_rounded,
                        color: Color(0xFF1A5C35),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          _isUploading
              ? Column(
                  children: const [
                    CircularProgressIndicator(color: Color(0xFF1A5C35)),
                    SizedBox(height: 8),
                    Text(
                      'Uploading...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5C35),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submitResource,
                    child: const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
