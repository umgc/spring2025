import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/experimental/assistant/chatgpt_client.dart';
import 'package:learninglens_app/Api/experimental/assistant/chatgpt_function_caller.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ChatGPTFunctionCallerView extends StatefulWidget {
  @override
  _ChatGPTFunctionCallerViewState createState() => _ChatGPTFunctionCallerViewState();
}

class _ChatGPTFunctionCallerViewState extends State<ChatGPTFunctionCallerView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, String>> _messages = [];
  late ChatGPTClient _chatGPT;
  bool _isThinking = false; // Tracks if the bot is thinking

  @override
  void initState() {
    super.initState();
    _chatGPT = ChatGPTClient(
      LocalStorageService.getOpenAIKey(),
      ChatGPTFunctionCaller(LmsFactory.getLmsService()),
    );
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": _controller.text});
      _isThinking = true; // Show thinking dots
    });

    final userMessage = _controller.text;
    _controller.clear();

    // Add a "thinking" message
    // setState(() {
    //   _messages.add({"sender": "bot", "text": "..."});
    // });

    String response = await _chatGPT.sendMessage(userMessage);

    setState(() {
      // _messages.removeLast(); // Remove "thinking" message
      _messages.add({"sender": "bot", "text": response});
      _isThinking = false; // Bot has finished responding
    });

    _focusNode.requestFocus(); // Refocus input field
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'EduLense Assistant (Beta)',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      body: Column(
        children: [
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

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.android, color: Colors.blueAccent),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            message["text"]!,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) ...[
                        SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, color: Colors.blueAccent),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(), // Loading indicator
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: "Ask ChatGPT...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                ClipOval(
                  child: Material(
                    color: Colors.blueAccent,
                    child: InkWell(
                      onTap: _sendMessage,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
