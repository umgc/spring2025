// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:async';

import 'package:memoryminder/src/database/model/audio.dart';
import 'package:memoryminder/src/typingIndicator.dart';
import 'package:dart_openai/dart_openai.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

// This is a AssistantScreen class.

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.conversation});

  final Audio? conversation;

  @override
  _AssistantScreenState createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  late FlutterTts tts;
  bool isPlaying = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _chatMessages = [];
  String prompt = "You are an assistant for someone with memory loss.";
  late Future<bool> goodAPIKey;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    goodAPIKey = loadAPIKey();
    initTTS();
  }

  @override
  void dispose() {
    super.dispose();
    tts.stop();
  }

  void initTTS() {
    tts = FlutterTts();

    tts.setStartHandler(() {
      setState(() {
        print("Playing");
        isPlaying = true;
      });
    });

    tts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        isPlaying = false;
      });
    });

    tts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        isPlaying = false;
      });
    });
  }

// Play or stop text to speech
  void toggleTTS(String text) async {
    if (isPlaying) {
      await tts.stop();
    } else {
      await tts.speak(text);
    }
  }

  // Add user messages to chat list then query ChatGPT API and add its
  // response to chat list
  Future<void> _handleUserMessage(String messageText, bool display) async {
    if (display) {
      // Create a user message
      ChatMessage userMessage = ChatMessage(
        messageText: messageText,
        isUserMessage: true,
        toggleTTS: (chatText) => toggleTTS(chatText),
      );

      // Add the user message to the chat
      setState(() {
        _chatMessages.add(userMessage);
      });
    }

    _scrollDown();

    // Clear the input field
    _messageController.clear();

    // Send the user message to the AI assistant (ChatGPT) and get a response
    String aiResponse = await getChatGPTResponse(messageText);

    // Create an AI message
    ChatMessage aiMessage = ChatMessage(
      messageText: aiResponse,
      isUserMessage: false,
      toggleTTS: (chatText) => toggleTTS(chatText),
    );

    // Add the AI message to the chat
    setState(() {
      _chatMessages.add(aiMessage);
    });

    _scrollDown();
  }

// Scroll to the bottom of the chat list with delay to make sure newest message is rendered
  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // Send user Message to ChatGPT 3.5 Turbo and return response
  Future<String> getChatGPTResponse(String userMessage) async {
    setState(() {
      _isTyping = true;
    });

    var messages = [
      OpenAIChatCompletionChoiceMessageModel(
        content: prompt,
        role: OpenAIChatMessageRole.system,
      ),
    ];
    for (ChatMessage chat in _chatMessages) {
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: chat.messageText,
          role: OpenAIChatMessageRole.user,
        ),
      );
    }
    messages.add(OpenAIChatCompletionChoiceMessageModel(
      content: userMessage,
      role: OpenAIChatMessageRole.user,
    ));

    print(messages);

    String response;
    try {
      OpenAIChatCompletionModel chatCompletion =
          await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: messages,
      );

      final content = chatCompletion.choices[0].message.content;

      response = 'Cora: $content';
    } on RequestFailedException catch (e) {
      _showAlert("API Request Error", e.message);
      response = "";
    } on Exception catch (e) {
      _showAlert("Unknown Error", e.toString());
      response = "";
    }

    setState(() {
      _isTyping = false;
    });

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: goodAPIKey, //Lock text input if API key is not found
        initialData: false,
        builder: (BuildContext context, AsyncSnapshot<bool> isLoad) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor:
                  const Color(0x00440000), // Set appbar background color
              centerTitle: true,
              title: const Text('Virtual Assistant',
                  style: TextStyle(color: Colors.black54)),
              elevation: 0,
              leading: const BackButton(color: Colors.black54),
            ),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/background.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 115, 20, 0),
                      controller: _scrollController,
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        return _chatMessages[index];
                      },
                    ),
                  ),
                  if (_isTyping) TypingIndicator(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25.0, 20, 0, 30),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            enabled:
                                isLoad.data, //Disable input without API key
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                            ),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: () {
                            String messageText = _messageController.text.trim();
                            if (messageText.isNotEmpty) {
                              _handleUserMessage(messageText, true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<bool> loadAPIKey() async {
    print("Load");
    // Load function will throw an error if memoryminder/.env is missing or empty
    // make sure this file holds your api key in the format "OPEN_AI_API_KEY=<key>"
    // Also, make sure not to share your API key or push it to Git
    await dotenv.load(fileName: ".env");
    String apiKeyEnv = dotenv.get('OPEN_AI_API_KEY', fallback: "");

    // If there's no API key, throw internal error
    if (apiKeyEnv.isEmpty) {
      _showAlert("API Key Error",
          "OpenAI API Key must be set to use the Virtual Assistant.");
      return false;
    } else {
      // Find the user's name to welcome them personally
      String userName;
      try {
        final directory = await getApplicationDocumentsDirectory();
        String path = directory.path;
        final file = File('$path/user_data.txt');
        String contents = await file.readAsString();
        List<String> details = contents.split(', ');
        userName = details[0];
      } on Exception catch (e) {
        // default if user file is not found (should not be possible outside of testing)
        userName = "Unidentified User";

        print(e.toString());
      }

      OpenAI.apiKey = apiKeyEnv;
      String prompt =
          "You are an assistant for $userName, who has memory loss.";
      if (widget.conversation != null) {
        print("path");
        String transcript = await getTranscript();
        if (transcript.isNotEmpty) {
          prompt +=
              "\n$userName wants to talk about the following conversation: \n{$transcript}";
        }
      }
      setState(() {
        this.prompt = prompt;
      });
      _handleUserMessage("Say hello.", false);
      return true;
    }
  }

  // Display alert when API key is empty
  FutureOr _showAlert(String title, String message) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ));
  }

  Future<String> getTranscript() async {
    File? file = await widget.conversation!.loadTranscriptFile();
    if (file != null) {
      print(file.path);
      try {
        return await file.readAsString();
      } on Exception catch (e) {
        _showAlert("Missing Transcript", "Transcript file could not be read.");
        print(e.toString());
        return "";
      }
    }
    _showAlert("Missing Transcript", "Transcript file not found.");

    return widget.conversation!.description ?? "";
  }
}

class ChatMessage extends StatelessWidget {
  final Function toggleTTS;
  final String messageText;
  final bool isUserMessage;

  const ChatMessage({super.key, 
    required this.messageText,
    required this.isUserMessage,
    required this.toggleTTS,
  });

  @override
  Widget build(BuildContext context) {
    var virtualAssistantIcon = Image.asset(
      'assets/icons/virtual_assistant.png',
      width: 25.0, // You can adjust the width and height
      height: 25.0, // as per your requirement
    );
    IconButton speakerButton = IconButton(
      icon: const Icon(IconData(0xe6c5, fontFamily: 'MaterialIcons')),
      onPressed: () {
        toggleTTS(messageText);
      },
    );
    const TextStyle messageStyle = TextStyle(
      color: Colors.white,
      fontSize: 16.0,
    );
    const TextStyle titleStyle = TextStyle(
      color: Color.fromRGBO(223, 223, 223, 1.0),
      fontSize: 16.0,
    );

    return Align(
      alignment: isUserMessage
          ? const Alignment(1.0, 0.0)
          : const Alignment(-1.0, 0.0),
      child: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.red[300] : Colors.blue[300],
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
                color: Colors.grey, //New
                blurRadius: 15,
                offset: Offset(0, 12))
          ],
        ),
        child: FractionallySizedBox(
          widthFactor: 0.85,
          child: ListTile(
            textColor: Colors.white,
            leading: isUserMessage ? null : virtualAssistantIcon,
            minLeadingWidth: 25,
            title: Text(
              isUserMessage ? "User:" : "CogniOpen Remote Assistant (Cora):",
              style: titleStyle,
            ),
            subtitle: Text(
              messageText,
              style: messageStyle,
            ),
            trailing: isUserMessage ? null : speakerButton,
            horizontalTitleGap: 16,
            minVerticalPadding: 16,
          ),
        ),
      ),
    );
  }
}
