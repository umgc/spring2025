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
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class S3Bucket {
  S3? connection;

  //attribute for singleton implementation
  static final S3Bucket _instance = S3Bucket._internal();

  //method for singleton implementation
  S3Bucket._internal() {
    //initialize the service on object load
    startService().then((value) {
      createBucket();
    });
  }

  //constructor for singlton implementation
  factory S3Bucket() {
    return _instance;
  }

  //establish connection based on .env values
  Future<void> startService() async {
    await dotenv.load(fileName: ".env"); //load .env file variables

    //Known deficiency - no option to select sub-regions (ex: us-east-2), so configure for lead (ex: us-east-1) for consistency in AWS services
    String region = (dotenv.get('region', fallback: "none"));
    String access = (dotenv.get('accessKey', fallback: "none"));
    String secret = (dotenv.get('secretKey', fallback: "none"));

    if (region == "none" || access == "none" || secret == "none") {
      appLogger.severe("S3 needs to be initialized");
      return;
    }

    connection = S3(
        //this region is hard-coded because the 'us-east-2' region would not run/load.
        region: region,
        credentials:
            AwsClientCredentials(accessKey: access, secretKey: secret));
    appLogger.info("S3 is connected...");
  }

  void createBucket() {
    String bucket = (dotenv.get('videoS3Bucket', fallback: "none"));

    if (bucket == "none") {
      appLogger.severe("S3 needs to be initialized");
      return;
    }
    //impotent method that creates bucket if it is not already present.
    Future<CreateBucketOutput> creating =
        connection!.createBucket(bucket: dotenv.get('videoS3Bucket'));
    creating.then((value) {
      appLogger.info("Bucket is created");
    });
  }

  Future<String> addAudioToS3(String title, String localPath) {
    // TODO Specify folder structure
    Uint8List bytes = File(localPath).readAsBytesSync();
    return _addToS3(title, bytes);
  }

  Future<String> addImageToS3(String title, String filepath) async {
    // TODO Specify folder structure
    Uint8List bytes = File(filepath).readAsBytesSync();
    return _addToS3("/images/$title", bytes);
  }

  Future<String> addFileToS3(String title, String manifest) async {
    // TODO Specify folder structure
    List<int> list = utf8.encode(manifest);
    Uint8List bytes = Uint8List.fromList(list);
    //use utf8.decode(bytes) to bring back into String.
    return _addToS3(title, bytes);
  }

  Future<String> addVideoToS3(String title, String localPath) {
    // TODO Specify folder structure
    appLogger.info("ADDING THIS TO S3 $title");
    Uint8List bytes = File(localPath).readAsBytesSync();
    return _addToS3(title, bytes);
  }

  //adds the Video to the S3 bucket
  //if the file already exists with that name, it is overwritten
  //method returns the name of the file being uploaded (used in queueing the object detection)
  Future<String> _addToS3(String title, Uint8List content) async {
    // TODO: Add logic to detect file type and create a folder
    // .mp3 files go to bucket/audio, .mp4 files go to bucket/video

    //^^ logic for this todo would be to include a "String prefix" parameter (for 'videos', 'images', etc.).
    // The "formattedTitle" method clears any folder path information, so one would need to append it back on
    // prior to content upload to S3

    String formattedTitle = FileManager.getFileNameForAWS(title);
    await connection!.putObject(
      bucket: dotenv.get('videoS3Bucket'),
      key: formattedTitle,
      body: content,
    );
    appLogger.info("content added to bucket: $formattedTitle");
    return title;
  }

  // Delete file from S3
  Future<bool> deleteFileFromS3(String key) async {
    try {
      await connection!
          .deleteObject(bucket: dotenv.get('videoS3Bucket'), key: key);
      return true;
    } catch (e) {
      appLogger.severe('Failed to delete the file from S3: $e');
      return false;
    }
  }
}
