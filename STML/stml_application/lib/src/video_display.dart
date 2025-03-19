// Author: Andrea Pellot
// Modified by: Ben Sutter
// Description: This class is used to display local videos within the gallery screen

import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoDisplay extends StatefulWidget {
  final String fullFilePath;

  const VideoDisplay({super.key, required this.fullFilePath});

  @override
  _VideoDisplayState createState() => _VideoDisplayState();
}

class _VideoDisplayState extends State<VideoDisplay> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  late Future<void> _video;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      File(widget.fullFilePath),
    );
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: 9 / 16,
    );
    _video = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _video,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Chewie(controller: _chewieController),
              ),
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
