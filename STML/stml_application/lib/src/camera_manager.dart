// Author: Ben Sutter
// Description: This class is used to control the video camera and associated auto record functionality.
//              This class also enables for photo captures when prompted in the gallery screen.

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/features/common/model/video.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/format_utils.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:memoryminder/src/utils/permission_manager.dart';
import "package:flutter/material.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memoryminder/src/video_processor.dart';

/// Camera manager class to handle camera functionality.
class CameraManager {
  CameraManager? cameraManager;
  List<CameraDescription> _cameras = <CameraDescription>[];
  late CameraController controller;

  static final CameraManager _instance = CameraManager._internal();

  bool isAutoRecording = false;
  bool uploadToRekognition = false;
  bool isInitialized = false;

  int autoRecordingInterval = 60;
  int cameraToUse = 1;

  late Image recentThumbnail;
  CameraManager._internal();

  factory CameraManager() {
    return _instance;
  }

  // Initalize the camera so it is ready for auto recording
  Future<void> initializeCamera() async {
    parseEnviromentSettings();

    // If permission is not granted then don't initialize
    if (!await PermissionManager.cameraPermissionGranted()) {
      isAutoRecording = false;
      return;
    }

    // Now, proceed with camera initialization
    _cameras = await availableCameras();

    // Make sure that there are available cameras if trying to use the front
    // 0 equals rear, 1 = front
    if (_cameras.length == 1) {
      cameraToUse = 0;
    } else if (_cameras.isEmpty) {
      FormatUtils.logBigMessage("ERROR: NO CAMERAS DETECTED");
      return;
    }
    controller = CameraController(_cameras[cameraToUse], ResolutionPreset.high);

    await controller.initialize();

    if (controller.value.isInitialized) {
      isInitialized = true;
      FormatUtils.logBigMessage("CAMERA HAS BEEN INITIALIZED");
    }
  }

  // Parse environmental variables to determine enabld features
  void parseEnviromentSettings() async {
    await dotenv.load(fileName: ".env");
    cameraToUse = int.parse(dotenv.get('cameraToUse', fallback: "1"));
    autoRecordingInterval =
        int.parse(dotenv.get('autoRecordInterval', fallback: "60"));
    isAutoRecording =
        dotenv.get('autoRecordEnabled', fallback: "false") == "true";
    uploadToRekognition =
        dotenv.get('autoUploadToRekognitionEnabled', fallback: "false") ==
            "true";
    String cameraUsed = (_cameras.length > 1) ? "front" : "rear";

    if (isAutoRecording) {
      FormatUtils.logBigMessage("AUTO VIDEO RECORDING IS ENABLED");
    } else {
      FormatUtils.logBigMessage("AUTO VIDEO RECORDING IS DISABLED");
    }

    if (uploadToRekognition) {
      FormatUtils.logBigMessage("AUTO REKOGNITION UPLOAD IS ENABLED");
    } else {
      FormatUtils.logBigMessage("AUTO REKOGNITION UPLOAD IS DISABLED");
    }

    appLogger
        .info("The camera that is being automatically used is the $cameraUsed");
  }

  // Starts the auto recording process
  void startAutoRecording() async {
    if (isAutoRecording) {
      // Delay for camera initialization
      Future.delayed(Duration(milliseconds: 1500), () {
        FormatUtils.logBigMessage("AUTO VIDEO RECORDING HAS STARTED");

        startRecordingInBackground();
      });
    }
  }

  // Stops any ongoing video recording
  Future<void> stopRecording() async {
    try {
      XFile? file = await controller.stopVideoRecording();

      await saveMediaLocally(file);
      if (uploadToRekognition) {
        VideoProcessor vp = VideoProcessor();
        vp.automaticallySendToRekognition();
      }
    } catch (e) {
      appLogger.severe(e);
    }
  }

  Future<void> manuallyStopRecording() async {
    isAutoRecording = false;
    await stopRecording();
  }

  Future<void> manuallyStartRecording() async {
    isAutoRecording = true;
    startRecordingInBackground();
  }

  // Automatically starts looping in teh background until the user stops the video
  void startRecordingInBackground() async {
    if (!controller.value.isInitialized) {
      appLogger.info('Error: Camera is not initialized.');
      appLogger.info('Auto recording has been canceled.');
      return;
    }

    // Start recording in the background

    if (!isAutoRecording) {
      return;
    }

    controller.startVideoRecording();

    // Record for 5 minutes (300 seconds)
    await Future.delayed(Duration(seconds: autoRecordingInterval));

    if (!isAutoRecording) {
      return;
    }

    await stopRecording();

    await Future.delayed(const Duration(seconds: 2));
    // Start the next loop of the recording
    startRecordingInBackground();
  }

  // Saves the media locally to app storage for use with other application aspects
  Future<void> saveMediaLocally(XFile mediaFile) async {
    // Get the local directory

    // Define a file name for the saved media, you can use a timestamp or any unique name
    const String fileExtension = 'mp4';

    final String timestamp = DateTime.now().toString();
    final String sanitizedTimestamp = timestamp.replaceAll(' ', '_');
    final String fileName =
        '$sanitizedTimestamp.$fileExtension'; // Use the determined file extension

    // Create a new file by copying the media file to the local directory
    final File localFile =
    File('${DirectoryManager.instance.videosDirectory.path}/$fileName');

    // Copy the media to the local directory
    await localFile.writeAsBytes(await mediaFile.readAsBytes());

    Video? vid = await DataService.instance.addVideo(videoFile: localFile);
    if (vid != null) {
      recentThumbnail = Image(image: vid.thumbnail!.image);
    }

    // Check if the media file has been successfully saved
    if (localFile.existsSync()) {
      appLogger.info('Media saved locally: ${localFile.path}');
      FileManager.getMostRecentVideo();
    } else {
      appLogger.severe('Failed to save media locally.');
    }
  }

  // Takes a photo and saves it to the directory specified
  Future<void> capturePhoto(Directory destinationDirectory) async {
    CameraManager manager = CameraManager();
    await manager.manuallyStopRecording();
    final String timestamp = DateTime.now().toString();
    final String sanitizedTimestamp = timestamp.replaceAll(' ', '_');
    final String fileName =
        '$sanitizedTimestamp.jpg'; // Use the determined file extension

    final String fullPath = '${destinationDirectory.path}/$fileName';
    final ImagePicker picker = ImagePicker();
    await picker
        .pickImage(source: ImageSource.camera)
        .then((XFile? recordedimage) async {
      if (recordedimage != null) {
        // Copy the image to the specified location
        File sourceFile = File(recordedimage.path);
        File destinationFile = File(fullPath);

        try {
          await sourceFile.copy(destinationFile.path);
          // You can now use the 'destinationFile' for further operations if needed.
          // Log the path of the saved image
          appLogger.info('Image saved at: ${destinationFile.path}');
          await DataService.instance.addPhoto(photoFile: destinationFile);
        } catch (e) {
          appLogger.severe('Error while copying the image: $e');
        }
      }
    });
    manager.initializeCamera();
  }
}
