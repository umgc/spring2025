// ignore_for_file: avoid_print, prefer_const_constructors
// Importing required packages and screens.
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:memoryminder/src/typingIndicator.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';

// Permission handler is used for handling permissions like microphone and storage access.
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';

/// Path provider helps in getting system directory paths to store the recorded audio.
import 'package:path_provider/path_provider.dart';

// Importing AWS Transcribe API and s3 bucket
import 'package:aws_transcribe_api/transcribe-2017-10-26.dart' as trans;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Record button glow effect
import 'package:avatar_glow/avatar_glow.dart';

const API_URL = 'https://api.openai.com/v1/chat/completions';
final API_KEY = dotenv.env['OPEN_AI_API_KEY']; // Replace with your API key

/// AudioScreen widget provides the main interface for audio recording.
class AudioScreen extends StatefulWidget {
  @override
  _AudioScreenState createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  // FlutterSoundRecorder is responsible for recording audio.
  FlutterSoundRecorder? _recorder;

  // FlutterSoundPlayer is responsible for playing back the recorded audio.
  FlutterSoundPlayer? _player;

  // Flags to track if recording or playback is currently in progress.
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isPaused = false;

  // Flag to track if transcription is loading
  bool _isTranscribing = false;

  // Variable to track the duration of the current recording.
  Duration _duration = const Duration(seconds: 0);

  // This variable will store the path where the recorded audio will be saved.
  String? _pathToSaveRecording;

  // Timer is used to update the duration of the recording in real-time.
  Timer? _timer;

  // Variables from env for s3
  final _bucketName = dotenv.env['videoS3Bucket'];
  final service = trans.TranscribeService(
    region: dotenv.env['region']!,
    credentials: trans.AwsClientCredentials(
      accessKey: dotenv.env['accessKey']!,
      secretKey: dotenv.env['secretKey']!,
    ),
  );
  var key2 = '';

  S3Service s3Connection = S3Service();

  String transcription = '';
  String transcriptionSummary = '';

  Audio? audio;
  int? audioId;

  @override
  void initState() {
    super.initState();

    // Initializing recorder and player instances.
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    /// Setting up the recorder by checking permissions.
    _initializeRecorder();
    _startRecording();
  }

  FutureOr _showPermissionDialogue() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Permission Required"),
              content: const Text(
                  "MemoryMinder audio recording features require access to your device's microphone. Please allow Microphone access in your device settings."),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                ),
              ],
            ));
  }

  /// This function initializes the recorder by checking necessary permissions.
  Future<void> _initializeRecorder() async {
    bool permissionsGranted = await _requestPermissions();

    if (!permissionsGranted) {
      _showPermissionDialogue();
      return;
    }
    await _recorder!.openRecorder();
  }

  /// This function requests necessary permissions for audio recording and storage.
  Future<bool> _requestPermissions() async {
    final micStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;

    if (micStatus.isGranted) {
      return true; // Already granted
    }

    // Request permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.storage,
    ].request();

    print(micStatus);
    print(storageStatus);
    return statuses[Permission.microphone]!.isGranted &&
        statuses[Permission.storage]!.isGranted;
  }

  @override
  void dispose() {
    // Cleanup operations: It's important to release resources to prevent memory leaks.
    _recorder!.closeRecorder();
    _player?.closePlayer();
    _timer?.cancel();
    super.dispose();
  }

  // Function to handle the starting of audio recording.
  Future<void> _startRecording() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      _showPermissionDialogue();
      return;
    }
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    key2 = DateTime.now().millisecondsSinceEpoch.toString();
    _pathToSaveRecording =
        '${appDocDirectory.path}/files/audios/$key2.wav'; // creates unique name
    debugPrint('initial app directory $appDocDirectory');

    await _recorder!.startRecorder(
        toFile: _pathToSaveRecording,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 134000);
    setState(() {
      _isRecording = true;
    });

    /// Timer to periodically update the duration of the audio recording in the UI.
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (_isRecording) {
        setState(() {
          _duration = _duration + Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _timer?.cancel();
    // Call Transcription after stopping the recording
    final s3UploadUrl =
        await s3Connection.addAudioToS3(key2, _pathToSaveRecording!);

    if (s3UploadUrl != null && s3UploadUrl.isNotEmpty) {
      _transcribeAudio(s3UploadUrl);
    } else {
      print("Error: s3UploadUrl is null or empty.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: No S3 URL returned')),
      );
    }
  }

  // Function to handle starting the playback of the recorded audio.
  Future<void> _startPlayback() async {
    if (_player!.isPlaying) {
      // If the player is currently playing, pause it
      await _player!.pausePlayer();
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
    } else if (_isPaused) {
      // If the player is paused, resume playback
      await _player!.resumePlayer();
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    } else {
      // If the player is stopped, start playing
      await _player!.openPlayer();
      await _player!.startPlayer(
        fromURI: _pathToSaveRecording,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
          _player!.closePlayer();
        },
      );

      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    }
  }

  // Function to handle stopping the playback of the recorded audio.
  Future<void> _stopPlayback() async {
    await _player!.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
    _player!.closePlayer();
  }

  Future<void> _transcribeAudio(String s3Url) async {
    // Ensure AWS credentials are properly configured
    try {
      String s3Uri = "s3://$_bucketName/audio/${s3Url.split('/').last}";
      print(s3Uri);

      // Starting the transcription job
      final response = await service.startTranscriptionJob(
        transcriptionJobName: '${key2}transcript',
        media: trans.Media(mediaFileUri: s3Uri),
        mediaFormat: trans.MediaFormat.wav,
        languageCode: trans.LanguageCode.enUs,
        settings: trans.Settings(
          showSpeakerLabels: true,
          maxSpeakerLabels:
              2, // specify the number of speakers you expect, adjust as needed
        ),
      );
      setState(() {
        _isTranscribing = true;
      });
      print(
          'Transcription job started with status: ${response.transcriptionJob?.transcriptionJobStatus}');

      // Poll for the transcription job's status
      while (true) {
        final jobResponse = await service.getTranscriptionJob(
          transcriptionJobName: '${key2}transcript',
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

              // Construct transcription text with speaker labels
              // Construct transcription text with speaker labels and start on a new line for each speaker
              var fullTranscription = '';
              String? currentSpeaker;

              for (var item in items) {
                // Check for speaker label
                if (item['type'] == 'pronunciation' &&
                    item.containsKey('speaker_label')) {
                  String speakerLabel =
                      _getCustomSpeakerLabel(item['speaker_label']);
                  if (currentSpeaker != speakerLabel) {
                    fullTranscription += '\n$speakerLabel: ';
                    currentSpeaker = speakerLabel;
                  }
                  fullTranscription += item['alternatives'][0]['content'] + ' ';
                } else if (item['type'] == 'punctuation') {
                  fullTranscription = fullTranscription.trim() +
                      item['alternatives'][0]['content'] +
                      ' ';
                }
              }
              setState(() {
                transcription = fullTranscription.trim();
                _isTranscribing = false;
              });
            } else {
              print(
                  'Failed to fetch transcript: ${transcriptResponse.statusCode}');
              _isTranscribing = false;
            }
            break;
          }
        } else if (jobResponse.transcriptionJob?.transcriptionJobStatus
                .toString() ==
            'TranscriptionJobStatus.failed') {
          print('Transcription job failed');
          _isTranscribing = false;
          break;
        }
        // Wait for a short interval before polling again
        await Future.delayed(Duration(seconds: 2));
      }
    } catch (e) {
      print('Error starting transcription: $e');
    }
    _saveTranscriptionToFile('${key2}transcript');
  }

  String _getCustomSpeakerLabel(String awsSpeakerLabel) {
    if (awsSpeakerLabel == 'spk_0') {
      return 'Speaker 1';
    } else if (awsSpeakerLabel == 'spk_1') {
      return 'Speaker 2';
    } else if (awsSpeakerLabel == 'spk_2') {
      return 'Speaker 3';
    } else if (awsSpeakerLabel == 'spk_3') {
      return 'Speaker 4';
    } else {
      return awsSpeakerLabel;
    }
  }

  Future _saveTranscriptionToFile(String transcriptionJobName) async {
    if (transcription.isEmpty) {
      print("Transcription is empty. Nothing to save.");
      setState(() {
        _isTranscribing = false;
      });
      return;
    }

    try {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      String filePath =
          '${appDocDirectory.path}/files/audios/transcripts/$transcriptionJobName.txt';

      File file = File(filePath);
      await file.writeAsString(transcription);

      print("Transcription saved at $filePath");
      transcriptionSummary = await summarizeFileContent(transcriptionJobName);
      _saveTranscriptionSummaryToFile(transcriptionJobName);
    } catch (e) {
      print("Error saving transcription");
    }
  }

  // Save transcription summary
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
      _sendToDatabase();
    } catch (e) {
      print("Error saving transcription");
    }
  }

  Future<String> summarizeFileContent(String fileName) async {
    try {
      // Read file content
      final directory = await getApplicationDocumentsDirectory();
      final file =
          File('${directory.path}/files/audios/transcripts/$fileName.txt');
      String content = await file.readAsString();

      print("Sending to OpenAI for summarization");
      // Send to OpenAI for Summarization
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
                  'Redact sensitive personal information from this content: $content'
            } // Your actual request
          ],
          'max_tokens': 500, // Adjust this as we need to
          'model': 'gpt-4',
        }),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse['choices'] == null ||
            jsonResponse['choices'].isEmpty) {
          throw Exception("No choices return from OpenAI.");
        }

        var summary =
            jsonResponse['choices'][0]['message']['content']?.trim() ?? "";

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

  Future<void> _sendToDatabase() async {
    // Call add method to db
    Directory appDocDirectory = await getApplicationDocumentsDirectory();
    String audioFilePath = '${appDocDirectory.path}/files/audios/$key2.wav';
    String transcriptFilePath =
        '${appDocDirectory.path}/files/audios/transcripts/${key2}transcript.txt';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(key2));
    final dateFormat = DateFormat('MM/dd/yyyy');
    final title = dateFormat.format(dateTime);
    audio = await DataService.instance.addAudio(
        title: title,
        description: "",
        audioFile: File(audioFilePath),
        transcriptFile: File(transcriptFilePath),
        summary: transcriptionSummary);
    audioId = audio?.id;
    print(audioId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: const Color(0x440000),
          elevation: 0,
          centerTitle: true,
          leading: const BackButton(color: Colors.black54),
          title: const Text('Audio Recording',
              style: TextStyle(color: Colors.black54)),
        ),
        body: Container(
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      if (_isRecording)
                        Column(
                          children: [
                            AvatarGlow(
                              glowColor: Colors.red,
                              glowRadiusFactor: 100.0,
                              duration: Duration(milliseconds: 2000),
                              repeat: true,
                              animate: true,
                              startDelay: Duration(milliseconds: 100),
                              child: Material(
                                // Replace this child with your own
                                elevation: 8.0,
                                shape: CircleBorder(),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey[100],
                                  radius: 70.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        style: ButtonStyle(
                                            shape: MaterialStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(75.0),
                                        ))),
                                        onPressed: () async {
                                          await _stopRecording();
                                        },
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.stop,
                                                size: 65, color: Colors.red),
                                            Text(
                                              "Stop Audio Recording",
                                              textAlign: TextAlign.center,
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _duration
                                  .toString()
                                  .split('.')
                                  .first
                                  .padLeft(8, "0"),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      else if (_pathToSaveRecording != null)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: 200.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: _isPlaying
                                            ? Icon(Icons.pause,
                                                size: 40,
                                                color: Color.fromARGB(
                                                    255, 2, 63, 129))
                                            : Icon(Icons.play_arrow,
                                                size: 40,
                                                color: Color.fromARGB(
                                                    255, 2, 63, 129)),
                                        onPressed: _isPlaying
                                            ? _startPlayback
                                            : _startPlayback,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.stop,
                                            size: 40,
                                            color: Color.fromARGB(
                                                255, 2, 63, 129)),
                                        onPressed: _isPlaying || _isPaused
                                            ? _stopPlayback
                                            : null,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _pathToSaveRecording = null;
                                            _duration =
                                                const Duration(seconds: 0);
                                            transcription = '';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color.fromARGB(255,
                                              2, 63, 129), // Background color
                                          foregroundColor:
                                              Colors.white, // Text color
                                        ),
                                        child: const Text('New Recording'),
                                      ),
                                      SizedBox(width: 32),
                                      ElevatedButton(
                                        onPressed: () async {
                                          // Your logic to remove audio
                                          if (audioId != null) {
                                            await DataService.instance
                                                .removeAudio(audioId!);
                                          }
                                          setState(() {
                                            _pathToSaveRecording = null;
                                            _duration =
                                                const Duration(seconds: 0);
                                            transcription = '';
                                          });
                                          // Notify user that the recording has been deleted
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Recording Deleted!')),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors
                                              .red, // background (button) color - adjust as needed
                                          foregroundColor: Colors
                                              .white, // foreground (text/icon) color - adjust as needed
                                        ),
                                        child: Icon(Icons
                                            .delete), // Use the `delete` icon
                                      )
                                    ],
                                  ),
                                  if (_isTranscribing) TypingIndicator(),
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Text(
                                      transcription,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
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
                            // Replace this child with your own
                            elevation: 8.0,
                            shape: CircleBorder(),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFFFFFFFF),
                              radius: 70.0,
                              child: TextButton(
                                onPressed: _startRecording,
                                style: ButtonStyle(
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(75.0),
                                ))),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mic,
                                        size: 60, color: Colors.green),
                                    Text(
                                      "Start Audio Recording",
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }
}
