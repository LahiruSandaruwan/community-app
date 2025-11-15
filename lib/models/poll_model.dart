import 'package:pocketbase/pocketbase.dart';

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

  factory PollModel.fromPocketBase(RecordModel record) {
    Map<String, List<String>> votes = {};
    final votesData = record.data['votes'];
    if (votesData != null && votesData is Map) {
      votesData.forEach((option, userIds) {
        if (userIds is List) {
          votes[option.toString()] = List<String>.from(userIds);
        }
      });
    }

    return PollModel(
      id: record.id,
      groupChatId: record.getStringValue('groupChatId'),
      question: record.getStringValue('question'),
      options: record.getListValue<String>('options'),
      votes: votes,
      createdBy: record.getStringValue('createdBy'),
      createdAt: DateTime.parse(record.getStringValue('createdAt', DateTime.now().toIso8601String())),
      expiresAt: record.getStringValue('expiresAt', '').isEmpty
          ? null
          : DateTime.parse(record.getStringValue('expiresAt')),
      allowMultiple: record.getBoolValue('allowMultiple'),
      isAnonymous: record.getBoolValue('isAnonymous'),
    );
  }

  Map<String, dynamic> toPocketBase() {
    return {
      'groupChatId': groupChatId,
      'question': question,
      'options': options,
      'votes': votes,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String() ?? '',
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
