import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String groupChatId;
  final String question;
  final List<String> options;
  final Map<String, List<String>> votes; // option index -> list of user IDs
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool allowMultiple;
  final bool isAnonymous;

  PollModel({
    required this.id,
    required this.groupChatId,
    required this.question,
    required this.options,
    required this.votes,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.allowMultiple = false,
    this.isAnonymous = false,
  });

  factory PollModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Map<String, List<String>> votes = {};
    if (data['votes'] != null) {
      final votesData = data['votes'] as Map<String, dynamic>;
      votesData.forEach((option, userIds) {
        votes[option] = List<String>.from(userIds ?? []);
      });
    }

    return PollModel(
      id: doc.id,
      groupChatId: data['groupChatId'] ?? '',
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      votes: votes,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      allowMultiple: data['allowMultiple'] ?? false,
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupChatId': groupChatId,
      'question': question,
      'options': options,
      'votes': votes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'allowMultiple': allowMultiple,
      'isAnonymous': isAnonymous,
    };
  }

  int getTotalVotes() {
    return votes.values.fold(0, (sum, userIds) => sum + userIds.length);
  }

  int getOptionVotes(String option) {
    return votes[option]?.length ?? 0;
  }
}
