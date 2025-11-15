import 'package:pocketbase/pocketbase.dart';
import 'message_model.dart';

class BookmarkModel {
  final String id;
  final String userId;
  final String messageId;
  final MessageModel message;
  final DateTime bookmarkedAt;
  final String? note; // Optional note about why it's bookmarked

  BookmarkModel({
    required this.id,
    required this.userId,
    required this.messageId,
    required this.message,
    required this.bookmarkedAt,
    this.note,
  });

  factory BookmarkModel.fromPocketBase(RecordModel record, MessageModel message) {
    return BookmarkModel(
      id: record.id,
      userId: record.getStringValue('userId'),
      messageId: record.getStringValue('messageId'),
      message: message, // This will be fetched separately in the service
      bookmarkedAt: DateTime.parse(record.getStringValue('bookmarkedAt', DateTime.now().toIso8601String())),
      note: record.getStringValue('note', '').isEmpty
          ? null
          : record.getStringValue('note'),
    );
  }

  Map<String, dynamic> toPocketBase() {
    return {
      'userId': userId,
      'messageId': messageId,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
      'note': note ?? '',
    };
  }
}
