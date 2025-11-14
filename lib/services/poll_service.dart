import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll_model.dart';

class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create poll
  Future<String> createPoll({
    required String groupChatId,
    required String question,
    required List<String> options,
    required String createdBy,
    DateTime? expiresAt,
    bool allowMultiple = false,
    bool isAnonymous = false,
  }) async {
    try {
      final docRef = await _firestore.collection('polls').add({
        'groupChatId': groupChatId,
        'question': question,
        'options': options,
        'votes': {},
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
        'allowMultiple': allowMultiple,
        'isAnonymous': isAnonymous,
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to create poll: $e';
    }
  }

  // Vote on poll
  Future<void> vote({
    required String pollId,
    required String userId,
    required String option,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final pollRef = _firestore.collection('polls').doc(pollId);
        final pollDoc = await transaction.get(pollRef);

        if (!pollDoc.exists) throw 'Poll not found';

        Map<String, dynamic> data = pollDoc.data()!;
        Map<String, dynamic> votes = Map<String, dynamic>.from(data['votes'] ?? {});

        // Add user to the option's voters list
        if (votes.containsKey(option)) {
          List<String> voters = List<String>.from(votes[option]);
          if (!voters.contains(userId)) {
            voters.add(userId);
            votes[option] = voters;
          }
        } else {
          votes[option] = [userId];
        }

        transaction.update(pollRef, {'votes': votes});
      });
    } catch (e) {
      throw 'Failed to vote: $e';
    }
  }

  // Get poll
  Stream<PollModel?> getPoll(String pollId) {
    return _firestore
        .collection('polls')
        .doc(pollId)
        .snapshots()
        .map((doc) => doc.exists ? PollModel.fromFirestore(doc) : null);
  }
}
