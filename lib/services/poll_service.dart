import 'package:pocketbase/pocketbase.dart';
import '../models/poll_model.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class PollService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<PollModel?>> _pollStreams = {};
  final Map<String, Timer> _pollingTimers = {};

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
      final now = DateTime.now();

      final pollData = {
        'groupChatId': groupChatId,
        'question': question,
        'options': options,
        'votes': {},
        'createdBy': createdBy,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'allowMultiple': allowMultiple,
        'isAnonymous': isAnonymous,
      };

      final record = await _pb.collection('polls').create(body: pollData);

      return record.id;
    } on ClientException catch (e) {
      throw 'Failed to create poll: ${e.response['message'] ?? e.toString()}';
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
      // Get current poll
      final poll = await _pb.collection('polls').getOne(pollId);

      Map<String, dynamic> votes = Map<String, dynamic>.from(poll.data['votes'] ?? {});

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

      await _pb.collection('polls').update(
        pollId,
        body: {'votes': votes},
      );
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw 'Poll not found';
      }
      throw 'Failed to vote: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to vote: $e';
    }
  }

  // Get poll
  Stream<PollModel?> getPoll(String pollId) {
    final streamKey = 'poll_$pollId';

    // Return existing stream if already active
    if (_pollStreams.containsKey(streamKey)) {
      return _pollStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<PollModel?>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _pollStreams.remove(streamKey);
      },
    );

    _pollStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final record = await _pb.collection('polls').getOne(pollId);

        if (!controller.isClosed) {
          controller.add(PollModel.fromPocketBase(record));
        }
      } on ClientException catch (e) {
        if (e.statusCode == 404) {
          if (!controller.isClosed) {
            controller.add(null);
          }
        } else {
          if (!controller.isClosed) {
            controller.addError('Failed to fetch poll: ${e.response['message'] ?? e.toString()}');
          }
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch poll: $e');
        }
      }
    }

    // Initial fetch
    fetchData();

    // Poll every 3 seconds
    _pollingTimers[streamKey] = Timer.periodic(
      const Duration(seconds: 3),
      (_) => fetchData(),
    );

    return controller.stream;
  }

  // Cleanup resources
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    for (var controller in _pollStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _pollStreams.clear();
  }
}
