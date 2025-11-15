import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../models/resource_model.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class ResourceService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<List<ResourceModel>>> _resourceStreams = {};
  final Map<String, Timer> _pollingTimers = {};

  // Get resources stream for a group chat
  Stream<List<ResourceModel>> getResources(String groupChatId) {
    final streamKey = 'resources_$groupChatId';

    // Return existing stream if already active
    if (_resourceStreams.containsKey(streamKey)) {
      return _resourceStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<List<ResourceModel>>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _resourceStreams.remove(streamKey);
      },
    );

    _resourceStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final records = await _pb.collection('resources').getFullList(
          filter: 'groupChatId = "$groupChatId"',
          sort: '-uploadedAt',
        );

        if (!controller.isClosed) {
          controller.add(
            records.map((record) => ResourceModel.fromPocketBase(record)).toList()
          );
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch resources: $e');
        }
      }
    }

    // Initial fetch
    fetchData();

    // Poll every 3 seconds
    _pollingTimers[streamKey] = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchData(),
    );

    return controller.stream;
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
      final now = DateTime.now();

      // Create multipart file for upload
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      );

      // Create resource record with file
      final formData = <String, dynamic>{
        'groupChatId': groupChatId,
        'fileName': fileName,
        'fileType': fileType,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'uploaderName': uploaderName,
        'uploadedAt': now.toIso8601String(),
      };

      final record = await _pb.collection('resources').create(
        body: formData,
        files: [multipartFile],
      );

      return record.id;
    } on ClientException catch (e) {
      throw Exception('Failed to upload resource: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to upload resource: $e');
    }
  }

  // Get a single resource
  Future<ResourceModel?> getResource(String resourceId) async {
    try {
      final record = await _pb.collection('resources').getOne(resourceId);
      return ResourceModel.fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get resource: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to get resource: $e');
    }
  }

  // Delete a resource
  Future<void> deleteResource(String resourceId) async {
    try {
      // PocketBase automatically deletes associated files when deleting a record
      await _pb.collection('resources').delete(resourceId);
    } on ClientException catch (e) {
      throw Exception('Failed to delete resource: ${e.response['message'] ?? e.toString()}');
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
      final records = await _pb.collection('resources').getFullList(
        filter: 'groupChatId = "$groupChatId" && fileType = "$fileType"',
        sort: '-uploadedAt',
      );

      return records
          .map((record) => ResourceModel.fromPocketBase(record))
          .toList();
    } on ClientException catch (e) {
      throw Exception('Failed to get resources by type: ${e.response['message'] ?? e.toString()}');
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
      final records = await _pb.collection('resources').getFullList(
        filter: 'groupChatId = "$groupChatId"',
        sort: '-uploadedAt',
      );

      final resources = records
          .map((record) => ResourceModel.fromPocketBase(record))
          .toList();

      // Filter by search query
      return resources
          .where((resource) =>
              resource.fileName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } on ClientException catch (e) {
      throw Exception('Failed to search resources: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to search resources: $e');
    }
  }

  // Get total storage used by group
  Future<int> getTotalStorageUsed(String groupChatId) async {
    try {
      final records = await _pb.collection('resources').getFullList(
        filter: 'groupChatId = "$groupChatId"',
      );

      int totalSize = 0;
      for (var record in records) {
        final resource = ResourceModel.fromPocketBase(record);
        totalSize += resource.fileSize;
      }

      return totalSize;
    } on ClientException catch (e) {
      throw Exception('Failed to get total storage: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to get total storage: $e');
    }
  }

  // Cleanup resources
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    for (var controller in _resourceStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _resourceStreams.clear();
  }
}
