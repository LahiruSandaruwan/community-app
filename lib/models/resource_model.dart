import 'package:pocketbase/pocketbase.dart';

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

  // Create from PocketBase record
  factory ResourceModel.fromPocketBase(RecordModel record) {
    return ResourceModel(
      id: record.id,
      groupChatId: record.getStringValue('groupChatId'),
      fileName: record.getStringValue('fileName'),
      fileUrl: record.getStringValue('fileUrl'),
      fileType: record.getStringValue('fileType'),
      fileSize: record.getIntValue('fileSize'),
      uploadedBy: record.getStringValue('uploadedBy'),
      uploaderName: record.getStringValue('uploaderName'),
      uploadedAt: DateTime.parse(record.getStringValue('uploadedAt', DateTime.now().toIso8601String())),
    );
  }

  // Convert to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'groupChatId': groupChatId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': uploadedAt.toIso8601String(),
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
