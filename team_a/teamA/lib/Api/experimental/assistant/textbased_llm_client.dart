import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:learninglens_app/Api/experimental/assistant/textbased_function_caller.dart';
import 'package:learninglens_app/Api/llm/llm_api_modules_base.dart';
import 'package:learninglens_app/Api/llm/prompt_engine.dart';
import 'package:learninglens_app/services/api_service.dart';

//  Replicate the functionality used in chatgpt_client, but swap over to prompt engineering instead of the function caller. 
//  This code gears the development for the assistant to be more generic in terms of which llm is used rather than relying on
//  functionality developement by OpenAI.
class TextBasedLLMClient {
  final LLM llm;
  final TextBasedFunctionCaller functionCaller;

  /// Maintains the entire conversation (system, user, assistant).
  final List<Map<String, String>> _conversation = [];

  TextBasedLLMClient(this.llm, this.functionCaller) {
    // Add system instructions once at the beginning
    _conversation.add({
      "role": "system",
      "content": PromptEngine.prompt_assistant
    });
  }

  /// Send a user message (multi-turn). If the LLM keeps calling functions,
  /// we'll keep looping until we get a plain text answer.
  Future<String> sendMessage(String userMessage) async {
    // 1) Add the user's message to conversation
    _conversation.add({
      "role": "user",
      "content": userMessage,
    });

    // 2) Multi-turn loop: keep calling the LLM until we get a non-CALL response
    while (true) {
      final llmReply = await _callLLM(_conversation);
      if (llmReply == null || llmReply.isEmpty) {
        return "No response from the LLM.";
      }

      final trimmedReply = llmReply.trim();

      // If the model requests a function call
      if (trimmedReply.startsWith("CALL ")) {
        // Handle the function call and add the result to the conversation
        final functionResult = await _handleFunctionCall(trimmedReply);

        // Insert the function result as an "assistant" message
        _conversation.add({
          "role": "assistant",
          "content": functionResult,
        });

        // Then loop again so the LLM can see that result and possibly call another function
      } else {
        // It's a final textual answer
        _conversation.add({
          "role": "assistant",
          "content": trimmedReply,
        });
        return trimmedReply;
      }
    }
  }

  /// Calls the OpenAI Chat Completion API with the entire conversation so far
  Future<String?> _callLLM(List<Map<String, String>> conversation) async {

    
    final response = await ApiService().httpPost(
      Uri.parse(llm.url),
      headers: {
        "Authorization": 'Bearer ${llm.apiKey}',
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "model": llm.model,
        "messages": conversation.map((m) {
          return {"role": m["role"], "content": m["content"]};
        }).toList(),
        "temperature": 0.7,
        "top_p": 0.9,
      }),
    );

    if (response.statusCode != 200) {
      return "Error from LLM: ${response.statusCode} => ${response.body}";
    }
  
    final jsonData = jsonDecode(response.body);
    if (jsonData["choices"] == null || jsonData["choices"].isEmpty) {
      return null;
    }

    return jsonData["choices"][0]["message"]["content"];
  }

  /// Parses a "CALL functionName(...)" string, calls the local function, returns its result
  Future<String> _handleFunctionCall(String callString) async {
    // Example: "CALL getQuizzes(courseID=101, quizTopicId=201)"
    final afterCall = callString.substring(5).trim(); // remove "CALL "
    final openParenIndex = afterCall.indexOf("(");
    if (openParenIndex == -1) {
      return "Error: malformed function call, missing '('";
    }

    final functionName = afterCall.substring(0, openParenIndex).trim();

    final closeParenIndex = afterCall.indexOf(")", openParenIndex);
    if (closeParenIndex == -1) {
      return "Error: malformed function call, missing ')'";
    }

    final argsString = afterCall.substring(openParenIndex + 1, closeParenIndex).trim();

    // Parse key=value pairs
    final Map<String, dynamic> argsMap = {};
    if (argsString.isNotEmpty) {
      final pairs = argsString.split(",");
      for (final pair in pairs) {
        final parts = pair.split("=");
        if (parts.length == 2) {
          final key = parts[0].trim();
          final val = parts[1].trim();
          argsMap[key] = val; // Keep as string; parse to int if you like
        }
      }
    }

    // Actually call the function
    final result = await functionCaller.callFunctionByName(functionName, argsMap);
    return result;
  }
}
