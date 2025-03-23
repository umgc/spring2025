import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/data/audio_repository.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioRepository _audioRepository = AudioRepository.instance;
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  AudioService() {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
  }

  // Initializes the recorder and player.
  Future<void> initializeRecorder() async {
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  bool isRecorderStopped() {
    return _recorder == null || _recorder!.isStopped;
  }

  Future<String> getRecordedFilePath() async {
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    return '${appDocDirectory.path}/files/audios/${DateTime.now().millisecondsSinceEpoch}.wav';
  }

  // Requests microphone and storage permissions.
  Future<bool> requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = Platform.isAndroid
        ? await Permission.manageExternalStorage.request()
        : PermissionStatus.granted;

    return micStatus.isGranted && storageStatus.isGranted;
  }

  // Starts recording audio and saves it to the given path.
  Future<String> startRecording() async {
    try {
      bool permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        throw Exception("Permissions not granted");
      }

      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDocDirectory.path}/files/audios/${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder!.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
      return filePath;
    } catch (e) {
      appLogger.severe("Error starting recording: $e");
      throw Exception("Recording failed");
    }
  }

  // Stops recording and returns the recorded file path.
  Future<void> stopRecording() async {
    try {
      await _recorder!.stopRecorder();
    } catch (e) {
      appLogger.severe("Error stopping recording: $e");
      throw Exception("Stop recording failed");
    }
  }

  // Plays a recorded audio file.
  Future<void> playRecording(String filePath) async {
    try {
      await _player!.startPlayer(fromURI: filePath);
    } catch (e) {
      appLogger.severe("Error playing audio: $e");
      throw Exception("Playback failed");
    }
  }

  // Pauses audio playback.
  Future<void> pausePlayback() async {
    try {
      await _player!.pausePlayer();
    } catch (e) {
      appLogger.severe("Error pausing audio: $e");
      throw Exception("Pause playback failed");
    }
  }

  // Stops audio playback.
  Future<void> stopPlayback() async {
    try {
      await _player!.stopPlayer();
    } catch (e) {
      appLogger.severe("Error stopping playback: $e");
      throw Exception("Stop playback failed");
    }
  }

  // Cleans up resources when no longer needed.
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
  }
}
