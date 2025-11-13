import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      communityId: data['communityId'] ?? '',
      groupChatId: data['groupChatId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      creatorName: data['creatorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      totalPoints: data['totalPoints'] ?? 100,
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
      submittedBy: List<String>.from(data['submittedBy'] ?? []),
      submissions: (data['submissions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              AssignmentSubmission.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      isActive: data['isActive'] ?? true,
      category: data['category'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'communityId': communityId,
      'groupChatId': groupChatId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'totalPoints': totalPoints,
      'attachmentUrls': attachmentUrls,
      'submittedBy': submittedBy,
      'submissions': submissions.map((key, value) => MapEntry(key, value.toMap())),
      'isActive': isActive,
      'category': category,
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
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      fileUrls: List<String>.from(map['fileUrls'] ?? []),
      notes: map['notes'],
      grade: map['grade'],
      feedback: map['feedback'],
      gradedAt: map['gradedAt'] != null
          ? (map['gradedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'fileUrls': fileUrls,
      'notes': notes,
      'grade': grade,
      'feedback': feedback,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
    };
  }

  bool get isGraded => grade != null;
}
