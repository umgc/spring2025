import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/experimental/assistant/chatgpt_function_caller.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ChatGPTClient {
  final String apiKey;
  final ChatGPTFunctionCaller functionCaller;

  // Keep a conversation so ChatGPT can chain calls
  final List<Map<String, dynamic>> _conversation = [];
  LmsType lmsType = LocalStorageService.getSelectedClassroom();

  ChatGPTClient(this.apiKey, this.functionCaller) {
    // Insert a system message once
    _conversation.add({
      "role": "system",
      "content": """
You are EduLense, a highly advanced e-learning assistant specialized in ${lmsType}. 
You can retrieve course info, quiz info, and show participants (students).

When the user mentions a course by name (like "Math" or "Science"):
1) Call getUserCourses() to find the matching course ID.

When the user asks for students/participants in a course:
2) Then call getCourseParticipants(courseId).

When the user references a quiz name (like "final quiz"):
3) Then call getQuizzes(courseID) to find the matching quiz ID.

Finally, if they ask for quiz grades (like "show me the quiz grades for X quiz in Y course"):
4) Call getQuizGradesForParticipants(courseId, quizId).

Always ask clarifying questions if uncertain about which course or quiz.
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
          },
          {
            "name": "getCourseParticipants",
            "description": "Fetches participants (students) in a course by course ID.",
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
