import 'package:flutter/material.dart';

class TranscriptionBox extends StatelessWidget {
  final TextEditingController controller;

  const TranscriptionBox({
    required this.controller,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color.fromARGB(255, 67, 67, 67)
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'AI Transcript will go here',
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
      );
  }
}
