import 'package:pocketbase/pocketbase.dart';

class AssignmentModel {
  final String id;
  final String communityId;
  final String groupChatId;
  final String title;
  final String description;
  final String createdBy; // Tutor ID
  final String creatorName;
  final DateTime createdAt;
  final DateTime dueDate;
  final int totalPoints;
  final List<String> attachmentUrls;
  final List<String> submittedBy; // Student IDs who submitted
  final Map<String, AssignmentSubmission> submissions;
  final bool isActive;
  final String? category; // 'homework', 'project', 'quiz', 'reading'

  AssignmentModel({
    required this.id,
    required this.communityId,
    required this.groupChatId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.creatorName,
    required this.createdAt,
    required this.dueDate,
    this.totalPoints = 100,
    this.attachmentUrls = const [],
    this.submittedBy = const [],
    this.submissions = const {},
    this.isActive = true,
    this.category,
  });

  factory AssignmentModel.fromPocketBase(RecordModel record) {
    // Parse submissions from JSON
    Map<String, AssignmentSubmission> submissions = {};
    final submissionsData = record.data['submissions'];
    if (submissionsData != null && submissionsData is Map) {
      submissionsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          submissions[key] = AssignmentSubmission.fromMap(value);
        }
      });
    }

    return AssignmentModel(
      id: record.id,
      communityId: record.getStringValue('communityId'),
      groupChatId: record.getStringValue('groupChatId'),
      title: record.getStringValue('title'),
      description: record.getStringValue('description'),
      createdBy: record.getStringValue('createdBy'),
      creatorName: record.getStringValue('creatorName'),
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      dueDate: DateTime.parse(record.getStringValue('dueDate', DateTime.now().toIso8601String())),
      totalPoints: record.getIntValue('totalPoints', 100),
      attachmentUrls: record.getListValue<String>('attachmentUrls'),
      submittedBy: record.getListValue<String>('submittedBy'),
      submissions: submissions,
      isActive: record.getBoolValue('isActive', true),
      category: record.getStringValue('category', '').isEmpty
          ? null
          : record.getStringValue('category'),
    );
  }

  Map<String, dynamic> toPocketBase() {
    return {
      'communityId': communityId,
      'groupChatId': groupChatId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'totalPoints': totalPoints,
      'attachmentUrls': attachmentUrls,
      'submittedBy': submittedBy,
      'submissions': submissions.map((key, value) => MapEntry(key, value.toMap())),
      'isActive': isActive,
      'category': category ?? '',
    };
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  int get submissionCount => submittedBy.length;
}

class AssignmentSubmission {
  final String studentId;
  final String studentName;
  final DateTime submittedAt;
  final List<String> fileUrls;
  final String? notes;
  final int? grade;
  final String? feedback;
  final DateTime? gradedAt;

  AssignmentSubmission({
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    this.fileUrls = const [],
    this.notes,
    this.grade,
    this.feedback,
    this.gradedAt,
  });

  factory AssignmentSubmission.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmission(
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      submittedAt: DateTime.parse(map['submittedAt'] ?? DateTime.now().toIso8601String()),
      fileUrls: List<String>.from(map['fileUrls'] ?? []),
      notes: map['notes']?.isEmpty ?? true ? null : map['notes'],
      grade: map['grade'],
      feedback: map['feedback']?.isEmpty ?? true ? null : map['feedback'],
      gradedAt: map['gradedAt'] != null && (map['gradedAt'] as String).isNotEmpty
          ? DateTime.parse(map['gradedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'submittedAt': submittedAt.toIso8601String(),
      'fileUrls': fileUrls,
      'notes': notes ?? '',
      'grade': grade,
      'feedback': feedback ?? '',
      'gradedAt': gradedAt?.toIso8601String() ?? '',
    };
  }

  bool get isGraded => grade != null;
}
