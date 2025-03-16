import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';

const String API_URL = 'https://transcribe.amazonaws.com';
final String? API_KEY = dotenv.env['OPEN_AI_API_KEY'];
final String? bucketName = dotenv.env['videoS3Bucket'];

class TranscriptionService {
  // Transcribes an audio file using AWS Transcribe and stores the results.
  Future<void> transcribeAudio(String s3Url, String key2) async {
    try {
      if (bucketName == null) {
        throw Exception(
            "AWS S3 bucket name is not set in environment variables.");
      }

      String s3Uri = "s3://$bucketName/$s3Url";
      appLogger.info('Starting transcription for: $s3Uri');

      // Initiate the transcription job
      final response = await _startTranscriptionJob(key2, s3Uri);
      if (response == null) return;

      // Poll for the transcription job's completion
      final String? transcriptText =
          await _pollTranscriptionJobCompletion(key2);
      if (transcriptText == null) return;

      // Save the transcription to file
      String? transcriptFilePath =
          await saveTranscriptionToFile('${key2}transcript', transcriptText);
      if (transcriptFilePath == null) return;

      // Save the summary
      String summary = await summarizeTranscription(transcriptText);
      await saveTranscriptionSummaryToFile('${key2}transcript', summary);

      appLogger.info("Transcription and summary saved successfully.");
    } catch (e) {
      appLogger.severe('Error during transcription: $e');
    }
  }

  // Starts an AWS Transcribe job and returns the response.
  Future<Map<String, dynamic>?> _startTranscriptionJob(
      String key2, String s3Uri) async {
    final Uri endpoint = Uri.parse('https://transcribe.amazonaws.com');
    final response = await http.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer $API_KEY',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'TranscriptionJobName': '${key2}transcript',
        'Media': {'MediaFileUri': s3Uri},
        'MediaFormat': 'wav',
        'LanguageCode': 'en-US',
        'Settings': {
          'ShowSpeakerLabels': true,
          'MaxSpeakerLabels': 2,
        }
      }),
    );

    if (response.statusCode == 200) {
      appLogger.info('Transcription job started successfully.');
      return jsonDecode(response.body);
    } else {
      appLogger.severe('Failed to start transcription: ${response.body}');
      return null;
    }
  }

  Future<String> getTranscriptionResult(String s3Url) async {
    try {
      // Extract key from S3 URL to use as job name
      String key2 = s3Url.split('/').last.split('.').first;

      // Poll for job completion
      final String? transcriptText =
          await _pollTranscriptionJobCompletion(key2);

      if (transcriptText != null) {
        return transcriptText;
      } else {
        throw Exception("Transcription job failed or returned no text.");
      }
    } catch (e) {
      appLogger.severe("Error fetching transcription result: $e");
      return "Error retrieving transcription.";
    }
  }

  // Polls AWS Transcribe until the transcription job completes.
  Future<String?> _pollTranscriptionJobCompletion(String key2) async {
    const int pollIntervalSeconds = 2;

    while (true) {
      final Uri endpoint = Uri.parse('https://transcribe.amazonaws.com');
      final response = await http.post(
        endpoint,
        headers: {
          'Authorization': 'Bearer $API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'TranscriptionJobName': '${key2}transcript'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jobResponse = jsonDecode(response.body);
        final String? status =
            jobResponse['TranscriptionJob']?['TranscriptionJobStatus'];

        if (status == 'COMPLETED') {
          final String? transcriptUri = jobResponse['TranscriptionJob']
              ?['Transcript']?['TranscriptFileUri'];
          if (transcriptUri != null) {
            return await _fetchTranscriptText(transcriptUri);
          }
        } else if (status == 'FAILED') {
          appLogger.severe('Transcription job failed.');
          return null;
        }
      } else {
        appLogger.severe('Error checking transcription job status.');
        return null;
      }

      await Future.delayed(Duration(seconds: pollIntervalSeconds));
    }
  }

  // Fetches the transcript text from AWS Transcribe.
  Future<String?> _fetchTranscriptText(String transcriptUri) async {
    final response = await http.get(Uri.parse(transcriptUri));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> items = jsonResponse['results']['items'];
      return _formatTranscription(items);
    } else {
      appLogger.severe('Failed to fetch transcript text.');
      return null;
    }
  }

  // Summarizes the transcription using OpenAI's API.
  Future<String> summarizeTranscription(String transcriptionText) async {
    try {
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Authorization': 'Bearer $API_KEY',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'prompt': 'Summarize: $transcriptionText',
          'max_tokens': 150,
          'model': 'text-davinci-003'
        }),
      );
      return response.statusCode == 200
          ? jsonDecode(response.body)['choices'][0]['text'].trim()
          : '';
    } catch (e) {
      appLogger.severe('Error summarizing transcription: $e');
      return '';
    }
  }

  /// Saves the transcription to a file and returns the file path.
  Future<String?> saveTranscriptionToFile(
      String transcriptionJobName, String transcription) async {
    if (transcription.isEmpty) {
      appLogger.warning("Transcription is empty. Nothing to save.");
      return null;
    }

    try {
      final directory = DirectoryManager.instance.transcriptsDirectory;
      final filePath = '${directory.path}/$transcriptionJobName.txt';

      final file = File(filePath);
      await file.writeAsString(transcription);

      appLogger.info("Transcription saved at $filePath");
      return filePath;
    } catch (e) {
      appLogger.severe("Error saving transcription: $e");
      return null;
    }
  }

  /// Saves the transcription summary to a file and returns the file path.
  Future<String?> saveTranscriptionSummaryToFile(
      String transcriptionSummaryName, String summary) async {
    if (summary.isEmpty) {
      appLogger.warning("Transcription summary is empty. Nothing to save.");
      return null;
    }

    try {
      final directory = DirectoryManager.instance.transcriptsDirectory;
      final filePath =
          '${directory.path}/${transcriptionSummaryName}_summary.txt';

      final file = File(filePath);
      await file.writeAsString(summary);

      appLogger.info("Transcription summary saved at $filePath");
      return filePath;
    } catch (e) {
      appLogger.severe("Error saving transcription summary: $e");
      return null;
    }
  }

  // Formats the transcription text with speaker labels and punctuation.
  String _formatTranscription(List<dynamic> items) {
    String fullTranscription = '';
    String? currentSpeaker;

    for (var item in items) {
      if (item['type'] == 'pronunciation' &&
          item.containsKey('speaker_label')) {
        String speakerLabel = getCustomSpeakerLabel(item['speaker_label']);
        if (currentSpeaker != speakerLabel) {
          fullTranscription += '\n$speakerLabel: ';
          currentSpeaker = speakerLabel;
        }
        fullTranscription += '${item['alternatives'][0]['content']} ';
      } else if (item['type'] == 'punctuation') {
        fullTranscription =
            fullTranscription.trim() + item['alternatives'][0]['content'] + ' ';
      }
    }

    return fullTranscription.trim();
  }

  // Maps AWS Transcribe speaker labels to readable labels.
  String getCustomSpeakerLabel(String awsSpeakerLabel) {
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
}
