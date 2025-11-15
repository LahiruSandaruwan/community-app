import 'package:pocketbase/pocketbase.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class BookmarkService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<List<Map<String, dynamic>>>> _bookmarkStreams = {};
  final Map<String, Timer> _pollingTimers = {};

  // Bookmark a message
  Future<void> addBookmark({
    required String userId,
    required String groupChatId,
    required String messageId,
    String? note,
  }) async {
    try {
      final now = DateTime.now();

      final bookmarkData = {
        'userId': userId,
        'messageId': messageId,
        'groupChatId': groupChatId,
        'bookmarkedAt': now.toIso8601String(),
        'note': note ?? '',
      };

      await _pb.collection('bookmarks').create(body: bookmarkData);
    } on ClientException catch (e) {
      throw 'Failed to bookmark message: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to bookmark message: $e';
    }
  }

  // Remove bookmark
  Future<void> removeBookmark({
    required String userId,
    required String messageId,
  }) async {
    try {
      // Find the bookmark by userId and messageId
      final records = await _pb.collection('bookmarks').getFullList(
        filter: 'userId = "$userId" && messageId = "$messageId"',
      );

      // Delete all matching bookmarks (should be only one)
      for (var record in records) {
        await _pb.collection('bookmarks').delete(record.id);
      }
    } on ClientException catch (e) {
      throw 'Failed to remove bookmark: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to remove bookmark: $e';
    }
  }

  // Check if message is bookmarked
  Future<bool> isBookmarked({
    required String userId,
    required String messageId,
  }) async {
    try {
      final records = await _pb.collection('bookmarks').getFullList(
        filter: 'userId = "$userId" && messageId = "$messageId"',
      );

      return records.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get all bookmarked messages for a user
  Stream<List<Map<String, dynamic>>> getBookmarks({
    required String userId,
  }) {
    final streamKey = 'bookmarks_$userId';

    // Return existing stream if already active
    if (_bookmarkStreams.containsKey(streamKey)) {
      return _bookmarkStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _bookmarkStreams.remove(streamKey);
      },
    );

    _bookmarkStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final records = await _pb.collection('bookmarks').getFullList(
          filter: 'userId = "$userId"',
          sort: '-bookmarkedAt',
        );

        List<Map<String, dynamic>> bookmarks = [];

        for (var bookmarkRecord in records) {
          final groupChatId = bookmarkRecord.data['groupChatId'];
          final messageId = bookmarkRecord.data['messageId'];

          // Fetch the actual message
          try {
            final messageRecord = await _pb.collection(AppConstants.messagesCollection).getOne(
              messageId,
            );

            final message = MessageModel.fromPocketBase(messageRecord);
            bookmarks.add({
              'bookmarkId': bookmarkRecord.id,
              'message': message,
              'groupChatId': groupChatId,
              'bookmarkedAt': bookmarkRecord.data['bookmarkedAt'],
              'note': bookmarkRecord.data['note'],
            });
          } catch (e) {
            print('Failed to fetch bookmarked message: $e');
          }
        }

        if (!controller.isClosed) {
          controller.add(bookmarks);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch bookmarks: $e');
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
    for (var controller in _bookmarkStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _bookmarkStreams.clear();
  }
}
