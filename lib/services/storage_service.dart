import 'dart:io';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'pocketbase_service.dart';

class StorageService {
  final PocketBase _pb = PocketBaseService().client;
  static const String _baseUrl = 'http://127.0.0.1:8090';

  // Upload profile picture
  // In PocketBase, we upload files as part of user record updates
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Validate file size
      int fileSize = await imageFile.length();
      if (fileSize > AppConstants.maxProfilePictureSize) {
        throw 'Image size must be less than 5MB';
      }

      String fileName = 'profile_$userId.jpg';

      // Create multipart file for upload
      final multipartFile = await http.MultipartFile.fromPath(
        'profilePicture',
        imageFile.path,
        filename: fileName,
      );

      // Update user record with profile picture
      final record = await _pb.collection(AppConstants.usersCollection).update(
        userId,
        body: {},
        files: [multipartFile],
      );

      // Get the file URL
      final profilePictureField = record.data['profilePicture'];
      if (profilePictureField != null && profilePictureField.isNotEmpty) {
        return '$_baseUrl/api/files/${AppConstants.usersCollection}/$userId/$profilePictureField';
      }

      throw 'Failed to get profile picture URL';
    } on ClientException catch (e) {
      throw 'Failed to upload profile picture: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  // Upload chat image
  // In PocketBase, we create a temporary record for chat images or upload with message
  Future<String> uploadChatImage({
    required String groupChatId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Create multipart file for upload
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: fileName,
      );

      // Create a chat_images record to store the image
      final record = await _pb.collection('chat_images').create(
        body: {
          'groupChatId': groupChatId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
        files: [multipartFile],
      );

      // Get the file URL
      final imageField = record.data['image'];
      if (imageField != null && imageField.isNotEmpty) {
        return '$_baseUrl/api/files/chat_images/${record.id}/$imageField';
      }

      throw 'Failed to get chat image URL';
    } on ClientException catch (e) {
      throw 'Failed to upload chat image: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to upload chat image: $e';
    }
  }

  // Delete file from storage
  // In PocketBase, files are deleted when the record is deleted
  // This is a placeholder for compatibility
  Future<void> deleteFile(String fileUrl) async {
    try {
      // Parse the file URL to get collection and record ID
      // Format: http://127.0.0.1:8090/api/files/{collection}/{recordId}/{filename}
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length >= 4 && pathSegments[1] == 'files') {
        final collection = pathSegments[2];
        final recordId = pathSegments[3];

        // Only delete if it's from chat_images collection
        if (collection == 'chat_images') {
          await _pb.collection('chat_images').delete(recordId);
        }
        // For other collections (users, etc.), we don't delete the record
        // as it may contain other important data
      }
    } on ClientException catch (e) {
      if (e.statusCode != 404) {
        throw 'Failed to delete file: ${e.response['message'] ?? e.toString()}';
      }
      // Ignore 404 - file already deleted
    } catch (e) {
      throw 'Failed to delete file: $e';
    }
  }

  // Get file URL from PocketBase record
  String getFileUrl({
    required String collectionId,
    required String recordId,
    required String filename,
  }) {
    return '$_baseUrl/api/files/$collectionId/$recordId/$filename';
  }
}
