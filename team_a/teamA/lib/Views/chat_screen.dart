import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/llm/openai_api.dart';
import 'package:learninglens_app/Api/lms/factory/lms_factory.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving/loading chat history
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:learninglens_app/Api/llm/enum/llm_enum.dart';
import 'package:learninglens_app/Api/llm/grok_api.dart';
import 'package:learninglens_app/Api/llm/perplexity_api.dart';
import 'dart:convert'; // For encoding and decoding chat history

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String _role = 'student'; // Role toggle for student/teacher
  final ScrollController _scrollController =
      ScrollController(); // For scrolling the chat
  SharedPreferences? _prefs; // SharedPreferences for saving chat history
  LlmType? selectedLLM;

  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // Load chat history when screen is initialized
    selectedLLM = LlmType.CHATGPT;
  }

  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedMessages = _prefs?.getString('chat_history');
    if (savedMessages != null) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(savedMessages));
      });
    }
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    if (_prefs != null) {
      await _prefs?.setString('chat_history', jsonEncode(_messages));
    }
  }

  // Function to handle user message sending and API response
  Future<void> _sendMessage() async {
    final input = _controller.text;
    final aiPrompt = "$input IMPORTANT: Do not use any Markdown syntax (e.g., #, *, **, etc.). Use plain text only.";

    if (input.isEmpty) {
      return;
    }
    final aiModel;
    if (selectedLLM == LlmType.CHATGPT) {
        aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
      } else if (selectedLLM == LlmType.GROK) {
        aiModel = GrokLLM(LocalStorageService.getGrokKey());
      } else if (selectedLLM == LlmType.PERPLEXITY) {
        // aiModel = OpenAiLLM(perplexityApiKey); 
        aiModel = PerplexityLLM(LocalStorageService.getPerplexityKey());
      } else {
        // default
        aiModel = OpenAiLLM(LocalStorageService.getOpenAIKey());
      }

    // Update UI to show user's message and reset text field
    setState(() {
      _messages.add({'text': input, 'sender': 'user'});
      _isLoading = true; // Show a loading indicator while waiting for response
    });

    _controller.clear(); // Clear the input field
    _scrollToBottom(); // Scroll to the bottom after sending the message
    await _saveChatHistory(); // Save chat history

    try {
      // Get ChatGPT response
      // final chatGPTService = OpenAiLLM();
      final prompt =
          _role == 'teacher' ? "You are assisting a teacher. $aiPrompt" : aiPrompt;
      final response = await aiModel.getChatResponse(prompt);

      setState(() {
        _messages.add({'text': response, 'sender': 'bot'});
        _isLoading = false;
      });

      _scrollToBottom(); // Scroll to the bottom after receiving the bot response
      await _saveChatHistory(); // Save chat history after bot response
    } catch (error) {
      setState(() {
        _messages.add({
          'text': 'Error: Could not fetch response. Please try again.',
          'sender': 'bot'
        });
        _isLoading = false;
      });
    }
  }

  // Function to clear chat history
  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _saveChatHistory(); // Save the empty state to clear saved chat history
  }

  // Function to toggle role (student/teacher)
  // void _toggleRole() { ***** Not used *****
  //   setState(() {
  //     _role = _role == 'student' ? 'teacher' : 'student';
  //   });
  // }

  // Scroll to the bottom of the chat list
  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Ask Chatbot!',
        userprofileurl: LmsFactory.getLmsService().profileImage ?? '',
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Main chat content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller:
                        _scrollController, // Attach the ScrollController
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUserMessage = message['sender'] == 'user';

                      return Align(
                        alignment: isUserMessage
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUserMessage
                                ? Colors.deepPurple
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color:
                                  isUserMessage ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(), // Loading indicator
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Enter your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.purpleAccent),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearChat, // Clear chat history
                      ),
                      // IconButton(
                      //   icon: Icon(Icons.switch_account),
                      //   onPressed: _toggleRole, // Toggle role between teacher and student
                      //   tooltip:
                      //       'Switch role to ${_role == 'student' ? 'Teacher' : 'Student'}',
                      // ),
                      DropdownButton<LlmType>(
                        value: selectedLLM,
                        onChanged: (LlmType? newValue) {
                          setState(() {
                            selectedLLM = newValue;
                          });
                        },
                        items: LlmType.values.map((LlmType llm) {
                          return DropdownMenuItem<LlmType>(
                            value: llm,
                            enabled: LocalStorageService.userHasLlmKey(llm),
                            child: Text(llm.displayName, style: TextStyle(
                              color: LocalStorageService.userHasLlmKey(llm) ? Colors.black87 : Colors.grey,
                              ),
                            ),
                          );
                        }).toList()
                      ),
                    ],
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