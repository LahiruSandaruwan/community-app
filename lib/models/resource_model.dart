import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String groupChatId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final String uploadedBy;
  final String uploaderName;
  final DateTime uploadedAt;

  ResourceModel({
    required this.id,
    required this.groupChatId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.uploadedBy,
    required this.uploaderName,
    required this.uploadedAt,
  });

  // Get file extension
  String get extension {
    return fileName.split('.').last.toLowerCase();
  }

  // Get formatted file size
  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Create from Firestore document
  factory ResourceModel.fromMap(Map<String, dynamic> map, String id) {
    return ResourceModel(
      id: id,
      groupChatId: map['groupChatId'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      uploadedBy: map['uploadedBy'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'groupChatId': groupChatId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  // Copy with method for updating
  ResourceModel copyWith({
    String? id,
    String? groupChatId,
    String? fileName,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    String? uploadedBy,
    String? uploaderName,
    DateTime? uploadedAt,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      groupChatId: groupChatId ?? this.groupChatId,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
