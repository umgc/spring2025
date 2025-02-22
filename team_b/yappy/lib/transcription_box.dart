import 'package:flutter/material.dart';

void main() {
  runApp(TranscriptionBox());
}

class TranscriptionBox extends StatelessWidget {
  const TranscriptionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Expanded(
              child: ChatBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBox extends StatelessWidget {
  const ChatBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color.fromARGB(255, 67, 67, 67)
        ),
        child: TextField(
          maxLines: null,
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
