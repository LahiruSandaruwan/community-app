import 'package:pocketbase/pocketbase.dart';
import '../models/user_stats_model.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class GamificationService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<UserStatsModel?>> _statsStreams = {};
  final Map<String, Timer> _pollingTimers = {};

  // Update user activity and award points
  Future<void> recordActivity({
    required String userId,
    required String activityType,
    int points = 10,
  }) async {
    try {
      // Try to get existing stats
      RecordModel? statsRecord;
      try {
        final records = await _pb.collection('userStats').getFullList(
          filter: 'userId = "$userId"',
        );
        if (records.isNotEmpty) {
          statsRecord = records.first;
        }
      } catch (e) {
        // Record doesn't exist yet
      }

      if (statsRecord == null) {
        // Create new stats
        final now = DateTime.now();
        await _pb.collection('userStats').create(
          body: {
            'userId': userId,
            'currentStreak': 1,
            'longestStreak': 1,
            'lastActiveDate': now.toIso8601String(),
            'totalPoints': points,
            'level': 1,
            'badges': [],
            'activityCounts': {activityType: 1},
          },
        );
      } else {
        // Update existing stats
        final data = statsRecord.data;
        final lastActiveStr = data['lastActiveDate'] as String?;
        final lastActive = lastActiveStr != null ? DateTime.parse(lastActiveStr) : null;
        final now = DateTime.now();

        int currentStreak = data['currentStreak'] ?? 0;
        int longestStreak = data['longestStreak'] ?? 0;

        // Check streak
        if (lastActive != null) {
          final daysDiff = now.difference(lastActive).inDays;
          if (daysDiff == 1) {
            currentStreak++;
          } else if (daysDiff > 1) {
            currentStreak = 1;
          }
          longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
        }

        final totalPoints = (data['totalPoints'] ?? 0) + points;
        final level = (totalPoints ~/ 100) + 1;

        Map<String, dynamic> activityCounts =
            Map<String, dynamic>.from(data['activityCounts'] ?? {});
        activityCounts[activityType] = (activityCounts[activityType] ?? 0) + 1;

        await _pb.collection('userStats').update(
          statsRecord.id,
          body: {
            'currentStreak': currentStreak,
            'longestStreak': longestStreak,
            'lastActiveDate': now.toIso8601String(),
            'totalPoints': totalPoints,
            'level': level,
            'activityCounts': activityCounts,
          },
        );
      }
    } on ClientException catch (e) {
      throw 'Failed to record activity: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to record activity: $e';
    }
  }

  // Get user stats
  Stream<UserStatsModel?> getUserStats(String userId) {
    final streamKey = 'stats_$userId';

    // Return existing stream if already active
    if (_statsStreams.containsKey(streamKey)) {
      return _statsStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<UserStatsModel?>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _statsStreams.remove(streamKey);
      },
    );

    _statsStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final records = await _pb.collection('userStats').getFullList(
          filter: 'userId = "$userId"',
        );

        if (!controller.isClosed) {
          if (records.isNotEmpty) {
            controller.add(UserStatsModel.fromPocketBase(records.first));
          } else {
            controller.add(null);
          }
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch user stats: $e');
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

  // Get leaderboard
  Future<List<UserStatsModel>> getLeaderboard({int limit = 10}) async {
    try {
      final records = await _pb.collection('userStats').getList(
        page: 1,
        perPage: limit,
        sort: '-totalPoints',
      );

      return records.items
          .map((record) => UserStatsModel.fromPocketBase(record))
          .toList();
    } on ClientException catch (e) {
      throw 'Failed to get leaderboard: ${e.response['message'] ?? e.toString()}';
    } catch (e) {
      throw 'Failed to get leaderboard: $e';
    }
  }

  // Cleanup resources
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    for (var controller in _statsStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _statsStreams.clear();
  }
}
