import 'package:pocketbase/pocketbase.dart';
import '../models/attendance_model.dart';
import 'pocketbase_service.dart';
import 'dart:async';

class AttendanceService {
  final PocketBase _pb = PocketBaseService().client;

  // Store active subscriptions for cleanup
  final Map<String, StreamController<List<AttendanceModel>>> _sessionStreams = {};
  final Map<String, Timer> _pollingTimers = {};

  // Get sessions stream for a group chat
  Stream<List<AttendanceModel>> getSessions(String groupChatId) {
    final streamKey = 'sessions_$groupChatId';

    // Return existing stream if already active
    if (_sessionStreams.containsKey(streamKey)) {
      return _sessionStreams[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<List<AttendanceModel>>.broadcast(
      onCancel: () {
        _pollingTimers[streamKey]?.cancel();
        _pollingTimers.remove(streamKey);
        _sessionStreams.remove(streamKey);
      },
    );

    _sessionStreams[streamKey] = controller;

    // Fetch and emit data periodically
    void fetchData() async {
      try {
        final records = await _pb.collection('attendance').getFullList(
          filter: 'groupChatId = "$groupChatId"',
          sort: '-startTime',
        );

        if (!controller.isClosed) {
          controller.add(
            records.map((record) => AttendanceModel.fromPocketBase(record)).toList()
          );
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError('Failed to fetch sessions: $e');
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

  // Create a new attendance session
  Future<String> createSession({
    required String groupChatId,
    required String sessionName,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now();

      final sessionData = {
        'groupChatId': groupChatId,
        'sessionName': sessionName,
        'createdBy': createdBy,
        'startTime': now.toIso8601String(),
        'endTime': null,
        'presentUserIds': [],
        'lateUserIds': [],
      };

      final record = await _pb.collection('attendance').create(body: sessionData);

      return record.id;
    } on ClientException catch (e) {
      throw Exception('Failed to create session: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  // Mark attendance for a user
  Future<void> markAttendance({
    required String sessionId,
    required String userId,
    bool isLate = false,
  }) async {
    try {
      // Get current session
      final session = await _pb.collection('attendance').getOne(sessionId);

      // Update appropriate array
      if (isLate) {
        final lateUserIds = List<String>.from(session.data['lateUserIds'] ?? []);
        if (!lateUserIds.contains(userId)) {
          lateUserIds.add(userId);
          await _pb.collection('attendance').update(
            sessionId,
            body: {'lateUserIds': lateUserIds},
          );
        }
      } else {
        final presentUserIds = List<String>.from(session.data['presentUserIds'] ?? []);
        if (!presentUserIds.contains(userId)) {
          presentUserIds.add(userId);
          await _pb.collection('attendance').update(
            sessionId,
            body: {'presentUserIds': presentUserIds},
          );
        }
      }
    } on ClientException catch (e) {
      throw Exception('Failed to mark attendance: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to mark attendance: $e');
    }
  }

  // End an attendance session
  Future<void> endSession(String sessionId) async {
    try {
      await _pb.collection('attendance').update(
        sessionId,
        body: {'endTime': DateTime.now().toIso8601String()},
      );
    } on ClientException catch (e) {
      throw Exception('Failed to end session: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // Get a single session
  Future<AttendanceModel?> getSession(String sessionId) async {
    try {
      final record = await _pb.collection('attendance').getOne(sessionId);
      return AttendanceModel.fromPocketBase(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get session: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Delete a session (optional - for cleanup)
  Future<void> deleteSession(String sessionId) async {
    try {
      await _pb.collection('attendance').delete(sessionId);
    } on ClientException catch (e) {
      throw Exception('Failed to delete session: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Get attendance stats for a user in a group
  Future<Map<String, int>> getUserAttendanceStats({
    required String groupChatId,
    required String userId,
  }) async {
    try {
      final records = await _pb.collection('attendance').getFullList(
        filter: 'groupChatId = "$groupChatId"',
      );

      int present = 0;
      int late = 0;
      int absent = 0;

      for (var record in records) {
        final session = AttendanceModel.fromPocketBase(record);

        if (session.presentUserIds.contains(userId)) {
          present++;
        } else if (session.lateUserIds.contains(userId)) {
          late++;
        } else {
          absent++;
        }
      }

      return {
        'present': present,
        'late': late,
        'absent': absent,
        'total': records.length,
      };
    } on ClientException catch (e) {
      throw Exception('Failed to get attendance stats: ${e.response['message'] ?? e.toString()}');
    } catch (e) {
      throw Exception('Failed to get attendance stats: $e');
    }
  }

  // Cleanup resources
  void dispose() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    for (var controller in _sessionStreams.values) {
      controller.close();
    }
    _pollingTimers.clear();
    _sessionStreams.clear();
  }
}
