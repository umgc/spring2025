// ignore_for_file: avoid_print, prefer_const_constructors
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:aws_transcribe_api/transcribe-2017-10-26.dart' as trans;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:avatar_glow/avatar_glow.dart';

const API_URL = 'https://api.openai.com/v1/chat/completions';
final API_KEY = dotenv.env['OPEN_AI_API_KEY'];

final String _bucketName = dotenv.env['videoS3Bucket']!;
final service = trans.TranscribeService(
    region: dotenv.env['region']!,
    credentials: trans.AwsClientCredentials(
      accessKey: dotenv.env['accessKey']!,
      secretKey: dotenv.env['secretKey']!,
    ));

class AudioScreen extends StatefulWidget {
  @override
  _AudioScreenState createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isTranscribing = false;
  Duration _duration = Duration.zero;
  String? _pathToSaveRecording;
  String? _recordingKey;
  Timer? _timer;
  String transcription = '';
  String transcriptionSummary = '';
  Audio? audio;
  int? audioId;
  String _currentStatus = "Idle";

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      _showPermissionDialogue();
    }
  }

  Future<void> _showPermissionDialogue() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "MemoryMinder audio recording features require access to your device's microphone. Please allow Microphone access in your device settings."),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    final micStatus = await Permission.microphone.request();
    final storageStatus = Platform.isAndroid
        ? await Permission.manageExternalStorage.request()
        : PermissionStatus.granted;
    return micStatus.isGranted && storageStatus.isGranted;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      _showPermissionDialogue();
      return;
    }

    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    _recordingKey = DateTime.now().millisecondsSinceEpoch.toString();
    _pathToSaveRecording =
        '${appDocDirectory.path}/files/audios/$_recordingKey.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        bitRate: 128000,
      ),
      path: _pathToSaveRecording!,
    );

    setState(() {
      _isRecording = true;
      _currentStatus = "Recording...";
      _duration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_isRecording) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _currentStatus = "Stopped";
    });

    _timer?.cancel();

    if (_pathToSaveRecording != null && _recordingKey != null) {
      final s3UploadUrl =
          await S3Service().addAudioToS3(_recordingKey!, _pathToSaveRecording!);

      if (s3UploadUrl != null && s3UploadUrl.isNotEmpty) {
        _transcribeAudio(s3UploadUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: No S3 URL returned')),
        );
      }
    }
  }

  Future<void> _transcribeAudio(String s3Url) async {
    try {
      if (_recordingKey == null) return;

      String s3Uri = "s3://$_bucketName/audio/${s3Url.split('/').last}";

      await service.startTranscriptionJob(
        transcriptionJobName: '${_recordingKey}transcript',
        media: trans.Media(mediaFileUri: s3Uri),
        mediaFormat: trans.MediaFormat.wav,
        languageCode: trans.LanguageCode.enUs,
      );

      setState(() {
        _isTranscribing = true;
        _currentStatus = "Transcribing...";
      });

      while (true) {
        final jobResponse = await service.getTranscriptionJob(
          transcriptionJobName: '${_recordingKey}transcript',
        );

        if (jobResponse.transcriptionJob?.transcriptionJobStatus.toString() ==
            'TranscriptionJobStatus.completed') {
          final transcriptUri =
              jobResponse.transcriptionJob?.transcript?.transcriptFileUri;

          if (transcriptUri != null) {
            final transcriptResponse = await http.get(Uri.parse(transcriptUri));

            if (transcriptResponse.statusCode == 200) {
              var jsonResponse = jsonDecode(transcriptResponse.body);
              var items = jsonResponse['results']['items'];
              var fullTranscription = '';
              String? currentSpeaker;

              for (var item in items) {
                if (item['type'] == 'pronunciation') {
                  if (item.containsKey('speaker_label')) {
                    String speakerLabel =
                        _getCustomSpeakerLabel(item['speaker_label']);
                    if (currentSpeaker != speakerLabel) {
                      fullTranscription += '\n$speakerLabel: ';
                      currentSpeaker = speakerLabel;
                    }
                  }

                  fullTranscription += item['alternatives'][0]['content'] + ' ';
                }
              }

              if (fullTranscription.trim().isEmpty) {
                fullTranscription =
                    "[No transcription detected — was the audio too short or unclear?]";
              }

              setState(() {
                transcription = fullTranscription.trim();
                _isTranscribing = false;
                _currentStatus = "Transcription Complete";
              });

              await _saveTranscriptionToFile('${_recordingKey}transcript');

              // Wait a moment to make sure filesystem is caught up
              await Future.delayed(Duration(milliseconds: 300));

              final directory = await getApplicationDocumentsDirectory();
              final transcriptFile = File(
                '${directory.path}/files/audios/transcripts/${_recordingKey}transcript.txt',
              );

              if (await transcriptFile.exists()) {
                print("Transcript file found. Starting summarization...");
                transcriptionSummary =
                    await summarizeFileContent('${_recordingKey}transcript');
                await _saveTranscriptionSummaryToFile(_recordingKey!);
              } else {
                print("Transcript file not found. Skipping summarization.");
              }
            }
          }

          break;
        }

        await Future.delayed(Duration(seconds: 2));
      }
    } catch (e) {
      print('Error during transcription: $e');
    }
  }

  String _getCustomSpeakerLabel(String awsSpeakerLabel) {
    switch (awsSpeakerLabel) {
      case 'spk_0':
        return 'Speaker 1';
      case 'spk_1':
        return 'Speaker 2';
      case 'spk_2':
        return 'Speaker 3';
      case 'spk_3':
        return 'Speaker 4';
      default:
        return awsSpeakerLabel;
    }
  }

  Future<void> _saveTranscriptionToFile(String transcriptionJobName) async {
    if (transcription.isEmpty) return;

    try {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String dirPath = '${appDocDirectory.path}/files/audios/transcripts';
      String filePath = '$dirPath/$transcriptionJobName.txt';

      // Make sure the folder exists
      await Directory(dirPath).create(recursive: true);

      File file = File(filePath);
      await file.writeAsString(transcription);

      print("Transcription saved at $filePath");
    } catch (e) {
      print("Error saving transcription: $e");
    }
  }

  Future<void> _saveTranscriptionSummaryToFile(
      String transcriptionSummaryName) async {
    if (transcriptionSummary.isEmpty) {
      print("Transcription summary is empty. Nothing to save");
      return;
    }

    try {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDocDirectory.path}/files/audios/transcripts/${transcriptionSummaryName}summary.txt';

      File file = File(filePath);
      await file.writeAsString(transcriptionSummary);

      print("Transcription Summary saved at $filePath");
      await _sendToDatabase();
    } catch (e) {
      print("Error saving transcription summary: $e");
    }
  }

  Future<String> summarizeFileContent(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file =
          File('${directory.path}/files/audios/transcripts/$fileName.txt');
      String content = await file.readAsString();

      print("Sending to OpenAI for summarization");

      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Authorization': 'Bearer $API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messages': [
            {
              'role': 'user',
              'content':
                  'Does this content contain sensitive personal information?: $content'
            }
          ],
          'max_tokens': 500,
          'model': 'gpt-4',
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var summary =
            jsonResponse['choices'][0]['message']['content']?.trim() ?? "";

        if (summary.toLowerCase().contains("yes")) {
          print("Sensitive Information Detected!");
          sendFirebaseNotification("Sensitive Data Alert",
              "Sensitive information detected in your transcript.");
        }

        if (summary.isEmpty) {
          throw Exception("OpenAI response was empty");
        }

        return summary;
      } else {
        print(
            'Failed to detect sensitive information. Response code: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error detecting sensitive information: $e');
      return '';
    }
  }

  Future<void> sendFirebaseNotification(String title, String body) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      String? token = await messaging.getToken();

      if (token == null) {
        print("Firebase token is null. Cannot send notification.");
        return;
      }

      final response = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=${dotenv.env['GOOGLE_CLOUD_API']}'
        },
        body: jsonEncode({
          "to": token,
          "notification": {"title": title, "body": body}
        }),
      );

      if (response.statusCode == 200) {
        print("Firebase Notification Sent!");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending Firebase notification: $e");
    }
  }

  Future<void> _sendToDatabase() async {
    try {
      final appDocDirectory = await getApplicationDocumentsDirectory();
      String audioFilePath =
          '${appDocDirectory.path}/files/audios/$_recordingKey.wav';
      String transcriptFilePath =
          '${appDocDirectory.path}/files/audios/transcripts/${_recordingKey}transcript.txt';

      final dateTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(_recordingKey!));
      final dateFormat = DateFormat('MM/dd/yyyy');
      final title = dateFormat.format(dateTime);

      audio = await DataService.instance.addAudio(
        title: title,
        description: "",
        audioFile: File(audioFilePath),
        transcriptFile: File(transcriptFilePath),
        summary: transcriptionSummary,
      );

      audioId = audio?.id;
      print("Audio saved with ID: $audioId");
    } catch (e) {
      print("Error saving to database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0x440000),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('Audio Recording',
            style: TextStyle(color: Colors.black54)),
      ),
      body: Column(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isRecording)
                  AvatarGlow(
                    glowColor: Colors.red,
                    glowRadiusFactor: 100.0,
                    duration: Duration(milliseconds: 2000),
                    repeat: true,
                    animate: true,
                    startDelay: Duration(milliseconds: 100),
                    child: Material(
                      elevation: 8.0,
                      shape: CircleBorder(),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        radius: 70.0,
                        child: IconButton(
                          onPressed: _stopRecording,
                          icon: Icon(Icons.stop, size: 65, color: Colors.red),
                        ),
                      ),
                    ),
                  )
                else
                  AvatarGlow(
                    glowColor: Colors.blue,
                    glowRadiusFactor: 100.0,
                    duration: Duration(milliseconds: 2000),
                    repeat: true,
                    animate: true,
                    startDelay: Duration(milliseconds: 100),
                    child: Material(
                      elevation: 8.0,
                      shape: CircleBorder(),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 70.0,
                        child: IconButton(
                          onPressed: _startRecording,
                          icon: Icon(Icons.mic, size: 60, color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  _currentStatus,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: transcription.isEmpty
                      ? Text('Transcription will appear here...')
                      : Text(transcription, style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: UiUtils.createBottomNavigationBar(context),
    );
  }
}
