import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;
import 'package:yappy/main.dart';
import 'package:yappy/services/file_handler.dart';


class OpenAIHelper {
  final List<Map<String, String>> messages = [];

  final String restaurantContextPrompt =
      '''You are a restaurant assistant.  Take the following audio transcript of a waiter taking patrons' orders and generate a summary of patrons' orders at a restaurant. You must separate out different speakers' orders and refer to them using using "Seat 1", "Seat 2", "Seat 3", etc.
        Example format:

        Seat 1: Hamburger, hold the lettuce, fries, Diet Dr. Pepper.

        Seat 2: Caesar salad, iced tea.

        Audio Transcript:
      ''';

  final String mechanicContextPrompt =
    '''You are a vehicle mechanic assistant.  Take the following audio transcript of a customer describing their vehicle's issues and generate a summary of vehicle's issues and include suggestions for resolution.
      Example format:

      Customer: My car is making a weird whirring noise at idle. It is also leaking oil.

      Audio Transcript:
    ''';

  final String medicalContextPrompt =
    '''You are a medical assistant.  Take the following audio transcript of a physician discussing a patient's concerns and generate a summary of patient's issues and include suggestions for resolution.
      Example format:

      Patient: I've been feeling really itchy recently. And I've been having trouble sleeping.

      Physician: I see. I recommend you take an antihistamine for the itching and try to avoid caffeine in the evenings.

      Audio Transcript:
    ''';
  
  Future<String> summarizeTranscription(int userId, String industry, int transcriptId) async {
    // Pulls the transcript text from the database
    Map<String, dynamic>? transcript = await dbHelper.getTranscriptById(transcriptId);
    if (transcript == null) {
      throw Exception('Transcript with given ID not found');
    }

    String contextPrompt = "";
    switch (industry) {
      case "Restaurant":
        contextPrompt = restaurantContextPrompt;
        break;
      case "Medical Doctor" || "Medical Patient":
        contextPrompt = medicalContextPrompt;
        break;
      case "Vehicle Maintenance":
        contextPrompt = mechanicContextPrompt;
        break;
    }

    String fullPromptToSend = contextPrompt + transcript['transcript_text_data'];

    List<OpenAIChatCompletionChoiceMessageModel> messages = [
      OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user, content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(fullPromptToSend)])
    ];

    try {
      final completion = await OpenAI.instance.chat
        .create(model: "gpt-4o-mini", messages: messages);
      // Adds the AI response to the previously saved transcript in the database
      await dbHelper.saveTranscriptAiResponse(userId: userId,
        transcriptId: transcriptId,
        text: transcript['transcript_text_data'],
        aiResponse: completion.choices[0].message.content.toString(), industry: industry);
      return completion.choices[0].message.content.toString();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> startTranscriptChatAssistant(String userQuery, String industry) async {

    /**
     * Chat assistant setup works as follows:
     * 1. Upload a file to OpenAI
     * 2. Create a vector store
     * 3. Attach the file to the vector store
     * 4. Create an assistant
     * 5. Create a thread for the assistant to use
     */

    FileHandler fileHandler = FileHandler();
    OpenAIHelper openAIHelper = OpenAIHelper();
    // todo: use specific industry to filter pulled transcripts
    String? response = "";
    var apiKey = preferences.getString('openai_api_key');
    String transcriptId = 'transcript_text_1742141070949_Restaurant.txt'; // todo: list
    String path = '${await fileHandler.localStoragePath}/$transcriptId'; // todo: multiple paths
    String? fileId = await openAIHelper.uploadFile(path, apiKey); // todo: multiple ids
    String? vectorStoreId = "", assistantId = "", threadId = "";

    bool successfulSetup = false;
    if (fileId != null) {
      vectorStoreId = await openAIHelper.createVectorStore(fileId, apiKey);
      if (vectorStoreId != null) {
        // Attach the file to the vector store
        bool attached = await openAIHelper.attachFileToVectorStore(vectorStoreId, fileId, apiKey); // todo: make plural
        if (attached) {
          // Create an Assistant
          assistantId = await createOpenAIAssistant(vectorStoreId, fileId, apiKey);
          if (assistantId != null) {
            // Create a Thread
            threadId = await createNewThreadForAssistant(apiKey);
            if (threadId != null) {
              print("🚀 All chat setup steps completed successfully!");
              successfulSetup = true;
            }
          }
        }
      }
    }

    /**
     * Chat assistant run works as follows:
     * 1. Send the user message to the created thread
     * 2. Run the assistant on the thread
     * 3. Query the current vector store using the assistant for information based on the user's input question
     * 4. Polls for results and returns them to the user as a response
     */
    if (successfulSetup) {
      await openAIHelper.sendMessageToThread(threadId!, userQuery, apiKey);
      String? runId = await openAIHelper.runAssistantOnThread(threadId, assistantId!, apiKey); // todo: replace "!" with null check
      if (runId != null) {
        print("🚀 Polling for Yappy assistant response!");
        response = await openAIHelper.getAssistantResponse(threadId, runId, apiKey);
        // Remove any unwanted characters
        response = response?.replaceAll(RegExp(r'[\u0000-\u001F]'), ''); // todo: fix weird characters
      }
    }
    return response;
  }

  // todo: look for industry keywords in the request text to determine the industry

  Future<String?> uploadFile(String filePath, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/files");

    var request = http.MultipartRequest("POST", url)
      ..headers["Authorization"] = "Bearer $apiKey"
      ..headers["OpenAI-Beta"] = "assistants=v2"
      ..fields["purpose"] = "assistants"
      ..files.add(await http.MultipartFile.fromPath("file", filePath));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var jsonResponse = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      print("✅ File uploaded: ${jsonResponse["id"]}");
      return jsonResponse["id"];
    } else {
      print("❌ File upload failed: $responseBody");
      return null;
    }
  }

  Future<String?> createVectorStore(String fileId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/vector_stores");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"name": "Transcript Vector Store"}),
    );
    var jsonResponse = jsonDecode(response.body);

    if (response.statusCode == 200) {
      print("✅ Vector store created: ${jsonResponse["id"]}");
      return jsonResponse["id"];
    } else {
      print("❌ Vector store creation failed: ${response.body}");
      return null;
    }
  }

  Future<bool> attachFileToVectorStore(String vectorStoreId, String fileId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/vector_stores/$vectorStoreId/files");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"file_id": fileId}),
    );

    if (response.statusCode == 200) {
      print("✅ File attached to vector store.");
      return true;
    } else {
      print("❌ Attaching file failed: ${response.body}");
      return false;
    }
  }

  Future<String?> createOpenAIAssistant(String vectorStoreId, String fileId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/assistants");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      },
      body: jsonEncode({
        "name": "Yappy",
        "instructions": "You can retrieve information from a vector store.",
        "model": "gpt-4o-mini",  // Ensure it's a valid model
        "tools": [
          {"type": "file_search"},
          {"type": "code_interpreter"},
        ],
        "tool_resources": {
          "file_search": {
            "vector_store_ids": [vectorStoreId]
          },
          "code_interpreter": {
            "file_ids": [fileId]
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print("✅ Assistant created: ${jsonResponse["id"]}");
      return jsonResponse["id"];  // Return Assistant ID
    } else {
      print("❌ Assistant creation failed: ${response.body}");
      return null;
    }
  }

   Future createNewThreadForAssistant(apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      },
      body: jsonEncode({}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print("✅ Thread created: ${jsonResponse["id"]}");
      return jsonResponse["id"];  // Return Thread ID
    } else {
      print("❌ Thread creation failed: ${response.body}");
      return null;
    }
  }

  Future<bool> sendMessageToThread(String threadId, String message, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/messages");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      },
      body: jsonEncode({
        "role": "user",
        "content": message
      }),
    );

    return response.statusCode == 200;
  }

  Future<String?> runAssistantOnThread(String threadId, String assistantId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/runs");

    var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      },
      body: jsonEncode({
        "assistant_id": assistantId
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse["id"];  // ✅ Return run ID
    } else {
      print("❌ Failed to run assistant: ${response.body}");
      return null;
    }
  }

  Future<String?> getAssistantResponse(String threadId, String runId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/runs/$runId");
    
    while (true) {
      await Future.delayed(Duration(seconds: 3)); // Poll every 3 seconds

      var response = await http.get(url, headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      });

      var jsonResponse = jsonDecode(response.body);
      String status = jsonResponse["status"];

      if (status == "completed") {
        break; // Exit loop when assistant has finished processing
      } else if (status == "failed" || status == "cancelled") {
        print("❌ Assistant run failed: $jsonResponse");
        return null;
      }
    }

    // Fetch latest messages in the thread to get assistant's response
    return getLatestAssistantMessage(threadId, apiKey);
  }

  Future<String?> getLatestAssistantMessage(String threadId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/messages");

    var response = await http.get(url, headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "OpenAI-Beta" : "assistants=v2"
    });

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var messages = jsonResponse["data"];

      for (var message in messages.reversed) { // Read messages from newest to oldest
        if (message["role"] == "assistant") {
          return message["content"][0]["text"]["value"];
        }
      }
    } else {
      print("❌ Failed to fetch messages: ${response.body}");
    }

    return null;
  }
}
