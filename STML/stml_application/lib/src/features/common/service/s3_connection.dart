// Author: David Bright
// Date: 2023-10-13
// Description: This class houses the methods to establish a connection to S3 and perform S3 operations
//              (namely add items to the S3 buckets)
// Last modified by: Ben Sutter
// Last modified on: 2023-11-04

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio_service.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/transcription_service.dart';

class S3Service {
  S3? _connection;

  // Attribute for singleton implementation
  static final S3Service _instance = S3Service._internal();
  factory S3Service() => _instance;

  S3Service._internal() {
    _initializeS3().then((_) {
      _createBucket();
    });
  }

  final TranscriptionService _transcriptionService = TranscriptionService();
  final AudioService _audioService = AudioService();

  //establish connection based on .env values
  Future<void> _initializeS3() async {
    await dotenv.load(fileName: ".env"); //load .env file variables

    // Known deficiency - no option to select sub-regions (ex: us-east-2), so configure for lead (ex: us-east-1) for consistency in AWS services
    String region = (dotenv.get('region', fallback: "none"));
    String access = (dotenv.get('accessKey', fallback: "none"));
    String secret = (dotenv.get('secretKey', fallback: "none"));

    if (region == "none" || access == "none" || secret == "none") {
      appLogger.severe("AWS S3 is not properly configured in .env file.");
      return;
    }

    _connection = S3(
        //this region is hard-coded because the 'us-east-2' region would not run/load.
        region: region,
        credentials:
            AwsClientCredentials(accessKey: access, secretKey: secret));
    appLogger.info("AWS S3 connection established.");
  }

  // Creates the S3 bucket if it does not exist
  void _createBucket() {
    String bucketName = (dotenv.get('videoS3Service', fallback: "none"));

    if (bucketName == "none") {
      appLogger.severe("S3 bucket is not configured");
      return;
    }
    // Important method that creates bucket if it is not already present.
    Future<CreateBucketOutput> creating =
        _connection!.createBucket(bucket: bucketName);
    creating.then((_) => appLogger.info("S3 Bucket is set up."));
  }

  // Uploads an audio file to S3 and returns the full URL
  Future<String?> addAudioToS3(String title, String localPath) async {
    String fileName = title.endsWith('.wav') ? title : "$title.wav";

    Uint8List bytes = File(localPath).readAsBytesSync();
    return _addToS3("audio", fileName, bytes);
  }

  // Uploads an image file to S3 and returns the full URL
  Future<String?> addImageToS3(String title, String filepath) async {
    Uint8List bytes = File(filepath).readAsBytesSync();
    return _addToS3("images", title, bytes);
  }

  // Uploads a video file to S3 and returns the full URL
  Future<String?> addVideoToS3(String title, String localPath) {
    Uint8List bytes = File(localPath).readAsBytesSync();
    return _addToS3("video", title, bytes);
  }

  Future<String?> addFileToS3(String title, String manifest) async {
    List<int> list = utf8.encode(manifest);
    Uint8List bytes = Uint8List.fromList(list);
    //use utf8.decode(bytes) to bring back into String.
    return _addToS3("files", title, bytes);
  }

  // Processes the recorded audio file: uploads to S3 and starts transcription.
  Future<String> uploadAudioAndTranscribe() async {
    try {
      if (!_audioService.isRecorderStopped()) {
        throw Exception("Recording is not stopped.");
      }

      // Get recorded file path from AudioService
      String filePath = await _audioService.getRecordedFilePath();
      String fileName = filePath.split('/').last;

      // Upload to S3
      final s3Service = S3Service();
      String s3Url = await s3Service.addAudioToS3(fileName, filePath) ??
          ""; // Ensures a non-null value

      // Start Transcription
      await _transcriptionService.transcribeAudio(
          s3Url, DateTime.now().millisecondsSinceEpoch.toString());

      return s3Url;
    } catch (e) {
      appLogger.severe("Error processing recording: $e");
      throw Exception("Error processing recording.");
    }
  }

  // Private method to upload files to S3 under a specific folder
  Future<String?> _addToS3(
      String folder, String title, Uint8List content) async {
    if (_connection == null) await _initializeS3();

    String bucketName = dotenv.get('videoS3Bucket');
    if (bucketName == "none") {
      appLogger.severe("S3 bucket name is not set in .env");
      return null;
    }

    String uniqueFileName = "${DateTime.now().millisecondsSinceEpoch}_$title";
    String s3Key = "$folder/$uniqueFileName";

    await _connection!.putObject(bucket: bucketName, key: s3Key, body: content);

    String s3Url = "https://$bucketName.s3.amazonaws.com/$s3Key";
    appLogger.info("File uploaded to S3: $s3Url");
    return s3Url;
  }

  // Deletes a file from S3
  Future<bool> deleteFileFromS3(String key) async {
    try {
      if (_connection == null) await _initializeS3();

      await _connection!
          .deleteObject(bucket: dotenv.get('videoS3Bucket'), key: key);
      appLogger.info("File deleted from S3: $key");
      return true;
    } catch (e) {
      appLogger.severe('Failed to delete the file from S3: $e');
      return false;
    }
  }
}
