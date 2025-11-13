import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile picture
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
      Reference ref = _storage
          .ref()
          .child(AppConstants.profilePicturesPath)
          .child(fileName);

      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload profile picture: $e';
    }
  }

  // Upload chat image
  Future<String> uploadChatImage({
    required String groupChatId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage
          .ref()
          .child(AppConstants.chatImagesPath)
          .child(groupChatId)
          .child(fileName);

      // Upload file
      UploadTask uploadTask = ref.putFile(imageFile);

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload chat image: $e';
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Failed to delete file: $e');
    }
  }

  // Get upload progress stream
  Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((TaskSnapshot snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
