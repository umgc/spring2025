import 'package:flutter/material.dart';

class TranscriptionBox extends StatelessWidget {
  final TextEditingController controller;

  const TranscriptionBox({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Gets the height of the user's screen
    double screenHeight = MediaQuery.of(context).size.height;

    // Wraps the UI in a sized box so that it can be adjusted to the screen's height
    return SizedBox(
      height: screenHeight *.4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color.fromARGB(255, 67, 67, 67),
        ),
        // Wraps the UI in a scrollbar so that the transcription data is scrollable and won't overflow
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: TextField(
              controller: controller,
              maxLines: null,
              readOnly: true,
              decoration: InputDecoration(
                  hintStyle: TextStyle(
                  color: Colors.white,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(10),
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

