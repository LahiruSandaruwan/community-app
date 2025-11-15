import 'dart:io';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VoiceMessageService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;

  // Start recording voice message
  Future<void> startRecording() async {
    try {
      // Check and request permission
      if (!await _recorder.hasPermission()) {
        throw 'Microphone permission denied';
      }

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
    } catch (e) {
      throw 'Failed to start recording: $e';
    }
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      throw 'Failed to stop recording: $e';
    }
  }

  // Cancel recording
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Failed to cancel recording: $e');
    }
  }

  // Get recording duration
  Future<Duration> getRecordingDuration(String filePath) async {
    try {
      await _player.setSourceDeviceFile(filePath);
      final duration = await _player.getDuration();
      return duration ?? Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  // Alias for getRecordingDuration
  Future<Duration> getAudioDuration(String filePath) async {
    return getRecordingDuration(filePath);
  }

  // Upload voice message to Firebase Storage
  Future<String> uploadVoiceMessage({
    required String filePath,
    required String groupChatId,
  }) async {
    try {
      final file = File(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_$timestamp.m4a';

      final ref = _storage
          .ref()
          .child('voice_messages')
          .child(groupChatId)
          .child(fileName);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Delete local file after upload
      await file.delete();

      return downloadUrl;
    } catch (e) {
      throw 'Failed to upload voice message: $e';
    }
  }

  // Play voice message
  Future<void> playVoiceMessage(String url) async {
    try {
      await _player.play(UrlSource(url));
    } catch (e) {
      throw 'Failed to play voice message: $e';
    }
  }

  // Pause playback
  Future<void> pausePlayback() async {
    await _player.pause();
  }

  // Resume playback
  Future<void> resumePlayback() async {
    await _player.resume();
  }

  // Stop playback
  Future<void> stopPlayback() async {
    await _player.stop();
  }

  // Get playback position
  Stream<Duration> get positionStream => _player.onPositionChanged;

  // Get playback duration
  Future<Duration?> getDuration() => _player.getDuration();

  // Seek to position
  Future<void> seek(Duration position) => _player.seek(position);

  // Set playback speed
  Future<void> setPlaybackSpeed(double speed) => _player.setPlaybackRate(speed);

  // Dispose resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
