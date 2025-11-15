import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/resource_model.dart';

class ResourceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get resources stream for a group chat
  Stream<List<ResourceModel>> getResources(String groupChatId) {
    return _firestore
        .collection('resources')
        .where('groupChatId', isEqualTo: groupChatId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Upload a resource file
  Future<String> uploadResource({
    required String groupChatId,
    required File file,
    required String fileName,
    required String uploadedBy,
    required String uploaderName,
  }) async {
    try {
      // Get file size
      final fileSize = await file.length();
      final fileType = fileName.split('.').last.toLowerCase();

      // Upload file to Firebase Storage
      final storageRef = _storage.ref().child(
          'resources/$groupChatId/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      final uploadTask = await storageRef.putFile(file);
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Create resource document in Firestore
      final docRef = await _firestore.collection('resources').add({
        'groupChatId': groupChatId,
        'fileName': fileName,
        'fileUrl': fileUrl,
        'fileType': fileType,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'uploaderName': uploaderName,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to upload resource: $e');
    }
  }

  // Get a single resource
  Future<ResourceModel?> getResource(String resourceId) async {
    try {
      final doc = await _firestore.collection('resources').doc(resourceId).get();

      if (!doc.exists) return null;

      return ResourceModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get resource: $e');
    }
  }

  // Delete a resource
  Future<void> deleteResource(String resourceId) async {
    try {
      // Get resource to get the file URL
      final resource = await getResource(resourceId);
      if (resource == null) return;

      // Delete file from Storage
      try {
        final fileRef = _storage.refFromURL(resource.fileUrl);
        await fileRef.delete();
      } catch (e) {
        // Continue even if storage deletion fails
        print('Failed to delete file from storage: $e');
      }

      // Delete document from Firestore
      await _firestore.collection('resources').doc(resourceId).delete();
    } catch (e) {
      throw Exception('Failed to delete resource: $e');
    }
  }

  // Get resources by file type
  Future<List<ResourceModel>> getResourcesByType({
    required String groupChatId,
    required String fileType,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .where('groupChatId', isEqualTo: groupChatId)
          .where('fileType', isEqualTo: fileType)
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get resources by type: $e');
    }
  }

  // Search resources by name
  Future<List<ResourceModel>> searchResources({
    required String groupChatId,
    required String query,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .where('groupChatId', isEqualTo: groupChatId)
          .orderBy('uploadedAt', descending: true)
          .get();

      final resources = snapshot.docs
          .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by search query
      return resources
          .where((resource) =>
              resource.fileName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search resources: $e');
    }
  }

  // Get total storage used by group
  Future<int> getTotalStorageUsed(String groupChatId) async {
    try {
      final snapshot = await _firestore
          .collection('resources')
          .where('groupChatId', isEqualTo: groupChatId)
          .get();

      int totalSize = 0;
      for (var doc in snapshot.docs) {
        final resource = ResourceModel.fromMap(doc.data(), doc.id);
        totalSize += resource.fileSize;
      }

      return totalSize;
    } catch (e) {
      throw Exception('Failed to get total storage: $e');
    }
  }
}
