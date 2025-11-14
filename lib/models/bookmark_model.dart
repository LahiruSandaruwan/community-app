import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory BookmarkModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookmarkModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      messageId: data['messageId'] ?? '',
      message: MessageModel.fromFirestore(
        // This will be fetched separately in the service
        doc,
      ),
      bookmarkedAt: (data['bookmarkedAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'messageId': messageId,
      'bookmarkedAt': Timestamp.fromDate(bookmarkedAt),
      'note': note,
    };
  }
}
