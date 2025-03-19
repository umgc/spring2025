// Author: Richard Tsang
// Modified by: Ben Sutter
// Date: 2023-10-05
// Description: Displays a camera preview and recording control options to the user
// Last modified by: Ben Sutter
// Last modified on: 2023-11-03

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:memoryminder/src/camera_manager.dart';

/// Camera home widget.
class VideoScreen extends StatefulWidget {
  /// Default Constructor
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() {
    return _CameraHomeState();
  }
}

/// Returns a suitable camera icon for [direction].
IconData getCameraLensIcon(CameraLensDirection direction) {
  switch (direction) {
    case CameraLensDirection.back:
      return Icons.camera_rear;
    case CameraLensDirection.front:
      return Icons.camera_front;
    case CameraLensDirection.external:
      return Icons.camera;
  }
  // This enum is from a different package, so a new value could be added at
  // any time. The example should keep working if that happens.
  // ignore: dead_code
  return Icons.camera;
}

void _logError(String code, String? message) {
  // ignore: avoid_print
  print('Error: $code${message == null ? '' : '\nError Message: $message'}');
}

class _CameraHomeState extends State<VideoScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late CameraManager cameraManager;
  late CameraController cameraController;
  bool enableAudio = true;

  final double _minAvailableZoom = 1.0;
  final double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  bool isRecording = false;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  @override
  void initState() {
    super.initState();
    //WidgetsBinding.instance.addObserver(this);
    cameraManager = CameraManager();
    cameraController = cameraManager.controller;
    isRecording = cameraManager.isAutoRecording;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const Image(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
        ),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('Camera', style: TextStyle(color: Colors.black54)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/images/background.jpg"),
                  fit: BoxFit.cover,
                ),
                color: Colors.black,
                border: Border.all(
                  color: isRecording ? Colors.redAccent : Colors.grey,
                  width: 5.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
        ],
      ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (!cameraController.value.isInitialized) {
      return Container();
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          cameraController,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (_pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await cameraController.setZoomLevel(_currentScale);
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
              color: Colors.black,
            ),
            child: IconButton(
              icon: isRecording
                  ? const Icon(Icons.pause)
                  : const Icon(Icons.circle),
              color: Colors.redAccent,
              onPressed: () {
                if (!cameraController.value.isRecordingVideo) {
                  onResumeButtonPressed();
                  setState(() {
                    isRecording = true;
                    const Icon(Icons.pause);
                  });
                } else {
                  onPauseButtonPressed();
                  setState(() {
                    isRecording = false;
                    const Icon(Icons.circle);
                  });
                }
              },
            ),
          ),
        )
      ],
    );
  }

  void onResumeButtonPressed() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Recording resumed")));
    cameraManager.manuallyStartRecording();
  }

  void onPauseButtonPressed() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Recording stopped")));
    cameraManager.manuallyStopRecording();
  }
}
