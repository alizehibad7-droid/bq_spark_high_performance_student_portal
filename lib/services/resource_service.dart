import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/resource_model.dart';

class ResourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ResourceModel>> streamResources() {
    return _db
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ResourceModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> addResource({
    required String title,
    required String description,
    required String link,
    required String category,
  }) async {
    await _db.collection('resources').add({
      'title': title,
      'description': description,
      'link': link,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteResource(String resourceId) async {
    await _db.collection('resources').doc(resourceId).delete();
  }

  Stream<int> streamResourceCount() {
    return _db
        .collection('resources')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<String?> uploadPdfToStorage({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('resources/notes')
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('PDF uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('PDF upload error: $e');
      return null;
    }
  }
}
