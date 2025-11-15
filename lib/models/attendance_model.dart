import 'package:pocketbase/pocketbase.dart';

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

  // Create from PocketBase record
  factory AttendanceModel.fromPocketBase(RecordModel record) {
    return AttendanceModel(
      id: record.id,
      groupChatId: record.getStringValue('groupChatId'),
      sessionName: record.getStringValue('sessionName'),
      createdBy: record.getStringValue('createdBy'),
      startTime: DateTime.parse(record.getStringValue('startTime', DateTime.now().toIso8601String())),
      endTime: record.getStringValue('endTime', '').isEmpty
          ? null
          : DateTime.parse(record.getStringValue('endTime')),
      presentUserIds: record.getListValue<String>('presentUserIds'),
      lateUserIds: record.getListValue<String>('lateUserIds'),
    );
  }

  // Convert to PocketBase record data
  Map<String, dynamic> toPocketBase() {
    return {
      'groupChatId': groupChatId,
      'sessionName': sessionName,
      'createdBy': createdBy,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String() ?? '',
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
