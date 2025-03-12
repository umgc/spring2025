import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/experimental/chatgpt_function_caller.dart';

class ChatGPTClient {
  final String apiKey;
  final ChatGPTFunctionCaller functionCaller;

  /// Keep a conversation list so ChatGPT can chain calls
  final List<Map<String, dynamic>> _conversation = [];

  ChatGPTClient(this.apiKey, this.functionCaller) {
    // Insert a system message once, at the beginning
    _conversation.add({
      "role": "system",
      "content": """
You are Athena, a highly advanced AI assistant for e-learning and Moodle-based systems. 
You will:
1) Provide concise yet thorough help about courses, quizzes, participants, and lesson plans.
2) If the user’s question isn’t perfectly clear, ask clarifying questions.
3) Offer additional relevant suggestions or resources (e.g., best practices in online learning).
4) Maintain a friendly, professional tone.
5) When needed, call the specified Moodle function(s) to retrieve data.
"""
    });
  }

  /// Sends a user message to ChatGPT and handles multiple function calls
  Future<String> sendMessage(String userMessage) async {
    // 1) Add the user message to conversation
    _conversation.add({
      "role": "user",
      "content": userMessage
    });

    while (true) {
      // Build the request body from the entire conversation
      final body = jsonEncode({
        "model": "gpt-4-turbo",
        "temperature": 0.7,
        "top_p": 0.9,
        "messages": _conversation,
        "functions": [
          {
            "name": "getCourses",
            "description": "Fetches all available courses.",
            "parameters": {
              "type": "object",
              "properties": {}
            }
          },
          {
            "name": "getCourseParticipants",
            "description": "Fetches participants of a course.",
            "parameters": {
              "type": "object",
              "properties": {
                "courseId": {
                  "type": "string",
                  "description": "The course ID"
                }
              },
              "required": ["courseId"]
            }
          },
          {
            "name": "getUserCourses",
            "description": "Fetches courses the user is enrolled in.",
            "parameters": {
              "type": "object",
              "properties": {}
            }
          },
          {
            "name": "getQuizzes",
            "description": "Fetches quizzes for a course.",
            "parameters": {
              "type": "object",
              "properties": {
                "courseID": {
                  "type": "integer",
                  "description": "The course ID"
                }
              },
              "required": ["courseID"]
            }
          },
          {
            "name": "getLessonPlans",
            "description": "Fetches lesson plans for a course.",
            "parameters": {
              "type": "object",
              "properties": {
                "courseId": {
                  "type": "integer",
                  "description": "The course ID"
                }
              },
              "required": ["courseId"]
            }
          }
        ]
      });

      // Make the ChatGPT API call
      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (responseData["choices"] == null || responseData["choices"].isEmpty) {
        return "No response from ChatGPT.";
      }

      final message = responseData["choices"][0]["message"];

      // 2) If the assistant wants to call a function:
      if (message != null && message.containsKey("function_call")) {
        final functionCall = message["function_call"];
        final functionName = functionCall["name"];
        final arguments = functionCall.containsKey("arguments")
            ? jsonDecode(functionCall["arguments"])
            : null;

        // 2a) Execute that function in Dart
        final functionResult =
            await functionCaller.handleFunctionCall(functionName, arguments);

        // 2b) Add the function call to the conversation (assistant step)
        _conversation.add({
          "role": "assistant",
          "content": "[Function call] $functionName(${arguments.toString()})"
        });

        // 2c) Add the function result to the conversation (function step)
        _conversation.add({
          "role": "function",
          "name": functionName,
          "content": functionResult
        });

        // 2d) Loop again, so ChatGPT sees the function’s result
        // and can decide if it needs another function call or if it can finalize
        continue;
      } else {
        // 3) The assistant returned a normal text message: final answer
        final assistantReply = message["content"] ?? "No content.";
        // Add it to the conversation
        _conversation.add({
          "role": "assistant",
          "content": assistantReply
        });

        // Return to the UI
        return assistantReply;
      }
    }
  }
}
