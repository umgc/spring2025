import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/experimental/chatgpt_function_caller.dart';

class ChatGPTClient {
  final String apiKey;
  final ChatGPTFunctionCaller functionCaller;

  // Keep a conversation so ChatGPT can chain calls
  final List<Map<String, dynamic>> _conversation = [];

  ChatGPTClient(this.apiKey, this.functionCaller) {
    // Insert a system message once
    _conversation.add({
      "role": "system",
      "content": """
You are Athena, a highly advanced e-learning assistant specialized in Moodle. 
Your primary goal is to retrieve quiz grades for a given user query. 
If the user references a course name (like "Math") or quiz name (like "final quiz") 
but doesn't provide IDs, you must call the appropriate function(s) to figure it out.

Use these steps:
1) If the user references a course name, call getUserCourses() and find the matching ID.
2) If the user references a quiz name, call getQuizzes(courseID) and find the matching quiz ID.
3) Finally, call getQuizGradesForParticipants(courseId, quizId) to fetch the grades.
Ask clarifying questions if uncertain.
"""
    });
  }

  Future<String> sendMessage(String userMessage) async {
    // Add user message
    _conversation.add({"role": "user", "content": userMessage});

    while (true) {
      final body = jsonEncode({
        "model": "gpt-4-turbo",
        "temperature": 0.7,
        "top_p": 0.9,
        "messages": _conversation,
        "functions": [
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
            "description": "Fetches quizzes for a course by ID.",
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
            "name": "getQuizGradesForParticipants",
            "description": "Fetches quiz grades for all participants in a given course & quiz.",
            "parameters": {
              "type": "object",
              "properties": {
                "courseId": {
                  "type": "string",
                  "description": "The course ID as string"
                },
                "quizId": {
                  "type": "integer",
                  "description": "The quiz ID"
                }
              },
              "required": ["courseId","quizId"]
            }
          }
        ]
      });

      // Call ChatGPT
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

      // If ChatGPT wants to call a function:
      if (message != null && message.containsKey("function_call")) {
        final functionCall = message["function_call"];
        final functionName = functionCall["name"];
        final arguments = functionCall.containsKey("arguments")
            ? jsonDecode(functionCall["arguments"])
            : null;

        // Execute the function
        final functionResult = await functionCaller.handleFunctionCall(functionName, arguments);

        // Append the function call to conversation
        _conversation.add({
          "role": "assistant",
          "content": "[Function call] $functionName(${arguments.toString()})"
        });

        // Append the function result
        _conversation.add({
          "role": "function",
          "name": functionName,
          "content": functionResult
        });

        // Loop to let ChatGPT see the function result
        continue;
      } else {
        // If normal text, final answer
        final assistantReply = message["content"] ?? "No content.";
        _conversation.add({"role": "assistant", "content": assistantReply});
        return assistantReply;
      }
    }
  }
}
