import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/experimental/chatgpt_client.dart';
import 'package:learninglens_app/Api/experimental/chatgpt_function_caller.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ChatGPTFunctionCallerView extends StatefulWidget {
  @override
  _ChatGPTFunctionCallerViewState createState() => _ChatGPTFunctionCallerViewState();
}

class _ChatGPTFunctionCallerViewState extends State<ChatGPTFunctionCallerView> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late ChatGPTClient _chatGPT;

  @override
  void initState() {
    super.initState();
    _chatGPT = ChatGPTClient(
      LocalStorageService.getOpenAIKey(),
      ChatGPTFunctionCaller(MoodleLmsService()),
    );
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": _controller.text});
    });

    final userMessage = _controller.text;
    _controller.clear();

    String response = await _chatGPT.sendMessage(userMessage);

    setState(() {
      _messages.add({"sender": "bot", "text": response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EduLense Assistant (beta)"),
      ),
      body: Column(
        children: [
          // Beta disclaimer
          Container(
            color: Colors.yellow[200],
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              "This feature is in beta and currently only works with ChatGPT.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isUser = message["sender"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask ChatGPT...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
