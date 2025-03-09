import 'dart:convert';
import 'dart:io';

import 'package:memoryminder/src/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum OnboardingState { GET_NAME, GET_ACTIVITY, GET_MEMORY, SUMMARY, GUIDE, END }

class Onboarding {
  String? userName;
  String? userFavoriteActivity;
  String? userFavoriteMemory;
  String? userSUMMARY;
  String? userGUIDE;
  String? userEND;

  int currentPageIndex = 0;
  final PageController controller = PageController(initialPage: 0);
  TextEditingController userInputController = TextEditingController();

  bool isListening = false;
  final SpeechToText speech = SpeechToText();
  OnboardingState state = OnboardingState.GET_NAME;
  List<OnboardingPage> pages =
      List.generate(6, (_) => OnboardingPage(conversation: []));

  Onboarding();

  get currentPage => currentPageIndex;

  Future<void> initialize() async {
    String aiPrompt = await getDynamicAIResponse();
    addMessageToConversation(aiPrompt, isUser: false);
  }

  Future<String> getDynamicAIResponse() async {
    switch (state) {
      case OnboardingState.GET_NAME:
        return "Hello and welcome! My name is Cora. What's your name?";
      case OnboardingState.GET_ACTIVITY:
        return "Nice to meet you, $userName! Can you also tell me a little about yourself? What are your favorite things to do?";
      case OnboardingState.GET_MEMORY:
        return "That sounds fun! My favorite activities include interacting with people and learning new things. Last question, what's one of your favorite memories?";
      case OnboardingState.SUMMARY:
        return generateSummary();
      case OnboardingState.GUIDE:
        return getLastPageMessage();
      case OnboardingState.END:
        return "Thank you for completing the onboarding! You can now explore the app.";
      default:
        return "Unknown state";
    }
  }

  Future<void> handleUserInput(BuildContext context) async {
    switch (state) {
      case OnboardingState.GET_NAME:
        userName = userInputController.text;
        break;
      case OnboardingState.GET_ACTIVITY:
        userFavoriteActivity = userInputController.text;
        break;
      case OnboardingState.GET_MEMORY:
        userFavoriteMemory = userInputController.text;
        break;
      case OnboardingState.SUMMARY:
        userSUMMARY = userInputController.text;
        break;
      case OnboardingState.GUIDE:
        userGUIDE = userInputController.text;
        break;
      case OnboardingState.END:
        userEND = userInputController.text;
        break;
      default:
        break;
    }
    userInputController.clear();
  }

  Future<void> nextPage(BuildContext context) async {
    currentPageIndex++;
    switch (state) {
      case OnboardingState.GET_NAME:
        state = OnboardingState.GET_ACTIVITY;
        break;
      case OnboardingState.GET_ACTIVITY:
        state = OnboardingState.GET_MEMORY;
        break;
      case OnboardingState.GET_MEMORY:
        state = OnboardingState.SUMMARY;
        break;
      case OnboardingState.SUMMARY:
        state = OnboardingState.GUIDE;
        break;
      case OnboardingState.GUIDE:
        state = OnboardingState.END;
        break;
      case OnboardingState.END:
        Navigator.pushReplacementNamed(context, '/homeScreen');
        return;
      case OnboardingState.END:
        userEND = userInputController.text;
        await saveUserInfoToFile(); // Save user information
        Navigator.pushReplacementNamed(context, '/homeScreen');
        return;
    }

    String aiPrompt = await getDynamicAIResponse();
    addMessageToConversation(aiPrompt, isUser: false);

    controller.nextPage(
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void addMessageToConversation(String message, {bool isUser = false}) {
    pages[currentPageIndex]
        .conversation
        .add(ConversationBubble(message, isUser: isUser));
  }

  Future<void> startListening() async {
    if (!isListening) {
      bool available = await speech.initialize(onStatus: statusListener);
      if (available) {
        speech.listen(onResult: resultListener);
        isListening = true;
      }
    } else {
      stopListening();
    }
  }

  void stopListening() {
    speech.stop();
    isListening = false;
  }

  void statusListener(String status) {
    if (status == "notListening") {
      isListening = false;
    }
  }

  void resultListener(dynamic result) {
    if (result.finalResult) {
      userInputController.text = result.recognizedWords;
      isListening = false;
    }
  }

  String generateSummary() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(DateTime.now().millisecondsSinceEpoch.toString()));
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final date = dateFormat.format(dateTime);
    return "On $date, you had an introductory conversation with Cora, the Virtual Assistant. You shared that you enjoy $userFavoriteActivity and reminisced about your favorite memory, which was $userFavoriteMemory.";
  }

  String getLastPageMessage() {
    return "Congratulations! You have successfully recorded your first conversation. To familiarize you with the application, we have created a guided tour that showcases all the amazing features you'll be using.";
  }

  Future<String> getAIResponse(String promptMessage) async {
    String openaiApiKey = dotenv.env['OPENAI_API_KEY']!;

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/engines/davinci/completions'),
      headers: {
        'Authorization': 'Bearer $openaiApiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'prompt': promptMessage,
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['text'].trim();
    } else {
      return 'Sorry, I couldn\'t process that right now.';
    }
  }

  OnboardingPage getCurrentPage() {
    return pages[currentPageIndex];
  }

  Future<void> saveUserInfoToFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/user_info.txt');

    try {
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('User Name: $userName');
      buffer.writeln('Favorite Activity: $userFavoriteActivity');
      buffer.writeln('Favorite Memory: $userFavoriteMemory');
      buffer.writeln('Summary: $userSUMMARY');
      buffer.writeln('Guide: $userGUIDE');
      buffer.writeln('End: $userEND');

      await file.writeAsString(buffer.toString());

      appLogger.info('User information saved to ${file.path}');
    } catch (e) {
      appLogger.info('Error saving user information: $e');
    }
  }
}

class OnboardingPage {
  final List<ConversationBubble> conversation;

  OnboardingPage({required this.conversation});
}

class ConversationBubble {
  final String text;
  final bool isUser;

  ConversationBubble(this.text, {this.isUser = false});
}
