import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String groupChatId;
  final String sessionName;
  final String createdBy;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> presentUserIds;
  final List<String> lateUserIds;

  AttendanceModel({
    required this.id,
    required this.groupChatId,
    required this.sessionName,
    required this.createdBy,
    required this.startTime,
    this.endTime,
    this.presentUserIds = const [],
    this.lateUserIds = const [],
  });

  // Create from Firestore document
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      groupChatId: map['groupChatId'] ?? '',
      sessionName: map['sessionName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      presentUserIds: List<String>.from(map['presentUserIds'] ?? []),
      lateUserIds: List<String>.from(map['lateUserIds'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'groupChatId': groupChatId,
      'sessionName': sessionName,
      'createdBy': createdBy,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'presentUserIds': presentUserIds,
      'lateUserIds': lateUserIds,
    };
  }

  // Copy with method for updating
  AttendanceModel copyWith({
    String? id,
    String? groupChatId,
    String? sessionName,
    String? createdBy,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? presentUserIds,
    List<String>? lateUserIds,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      groupChatId: groupChatId ?? this.groupChatId,
      sessionName: sessionName ?? this.sessionName,
      createdBy: createdBy ?? this.createdBy,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      presentUserIds: presentUserIds ?? this.presentUserIds,
      lateUserIds: lateUserIds ?? this.lateUserIds,
    );
  }
}
