import 'package:flutter/material.dart';

class TranscriptionBox extends StatefulWidget {
  final TextEditingController controller;

  const TranscriptionBox({
    required this.controller,
    super.key,
  });

  @override
  _TranscriptionBoxState createState() => _TranscriptionBoxState();
}

class _TranscriptionBoxState extends State<TranscriptionBox> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color.fromARGB(255, 67, 67, 67),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              readOnly: true,
              decoration: InputDecoration(
                hintText: "Transcription will appear here...",
                hintStyle: TextStyle(color: Colors.white),
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

