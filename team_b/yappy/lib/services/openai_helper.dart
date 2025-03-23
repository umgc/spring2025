import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yappy/main.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:yappy/services/file_handler.dart';

class OpenAIHelper {
  final List<Map<String, String>> messages = [];
  final currentOpenAIModel = "gpt-4o-mini"; // Ensure this is a current and valid model

  final String restaurantContextPrompt =
      '''You are a restaurant assistant.  Take the following audio transcript of a waiter taking patrons' orders and generate a summary of patrons' orders at a restaurant. You must separate out different speakers' orders and refer to them using using "Seat 1", "Seat 2", "Seat 3", etc.
        
        Respond in plain text.
        
        Example format:

        Seat 1: Hamburger, hold the lettuce, fries, Diet Dr. Pepper.

        Seat 2: Caesar salad, iced tea.

        Audio Transcript:
      ''';

  final String mechanicContextPrompt =
    '''You are a vehicle mechanic assistant.  Take the following audio transcript of a customer describing their vehicle's issues and generate a summary of vehicle's issues and include suggestions for resolution.
      
      Respond in plain text.
      
      Example format:

      Customer: My car is making a weird whirring noise at idle. It is also leaking oil.

      Audio Transcript:
    ''';

  final String medicalContextPrompt =
    '''You are a medical assistant.  Take the following audio transcript of a physician discussing a patient's concerns and generate a summary of patient's issues and include suggestions for resolution.
      
      Respond in plain text.
      
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
        .create(model: currentOpenAIModel, messages: messages);
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
    DatabaseHelper dbHelper = DatabaseHelper();
    String? response = "";
    String? apiKey = preferences.getString('openai_api_key');
    
    // Pulls all transcripts for the current industry
    List<Map<String, dynamic>> transcripts = await dbHelper.getAllTranscriptsByIndustry(industry);
    // Saves all industry transcripts to local storage
    List<String> localTranscriptFileNames = [];
    for (var transcript in transcripts) {
      String currentFileName = await fileHandler.saveTranscriptTextToLocal(dbHelper, transcript['transcript_id']);
      localTranscriptFileNames.add(currentFileName);
    }

    List<String> transcriptPaths = [];
    for (String transcriptId in localTranscriptFileNames) {
      String path = '${await fileHandler.localStoragePath}/$transcriptId';
      transcriptPaths.add(path);
    }

    List<String>? fileIds = await openAIHelper.uploadFile(transcriptPaths, apiKey);
    String? vectorStoreId = "", assistantId = "", threadId = "";

    bool successfulSetup = false;
    if (fileIds != null) {
      vectorStoreId = await openAIHelper.createVectorStore(apiKey);
      if (vectorStoreId != null) {
        // Attach the files to the vector store
        bool attached = await openAIHelper.attachFilesToVectorStore(vectorStoreId, fileIds, apiKey);
        if (attached) {
          // Create an Assistant
          assistantId = await createOpenAIAssistant(vectorStoreId, fileIds, apiKey);
          if (assistantId != null) {
            // Create a Thread
            threadId = await createNewThreadForAssistant(apiKey);
            if (threadId != null) {
              debugPrint("✅ All chat setup steps completed successfully!");
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
      String? runId = await openAIHelper.runAssistantOnThread(threadId, assistantId!, apiKey!);
      if (runId != null) {
        debugPrint("🚀 Polling in background for Yappy assistant response!");
        response = await openAIHelper.getAssistantResponseInBackground(threadId, runId, apiKey);
      }
    }

    // Clean up local storage after assistant processing has completed
    for (String currentFileName in localTranscriptFileNames) {
      await fileHandler.deleteFile(currentFileName);
    }

    return response;
  }

  Future<List<String>?> uploadFile(List<String> filePaths, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/files");

    List<String> fileIds = [];
    for (String filePath in filePaths) {
      var request = http.MultipartRequest("POST", url)
      ..headers["Authorization"] = "Bearer $apiKey"
      ..headers["OpenAI-Beta"] = "assistants=v2"
      ..fields["purpose"] = "assistants"
      ..files.add(await http.MultipartFile.fromPath("file", filePath));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        debugPrint("✅ File uploaded: ${jsonResponse["id"]}");
        fileIds.add(jsonResponse["id"]);
      } else {
      debugPrint("❌ File upload failed: $responseBody");
      return null;
      }
    }
    return fileIds;
  }

  Future<String?> createVectorStore(apiKey) async {
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
      debugPrint("✅ Vector store created: ${jsonResponse["id"]}");
      return jsonResponse["id"];
    } else {
      debugPrint("❌ Vector store creation failed: ${response.body}");
      return null;
    }
  }

  Future<bool> attachFilesToVectorStore(String vectorStoreId, List<String> fileIds, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/vector_stores/$vectorStoreId/files");

    for (String fileId in fileIds) {
      var response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"file_id": fileId}),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Attaching file failed: ${response.body}");
        return false;
      } else {
        debugPrint("✅ File with ID $fileId attached to vector store.");
      }
    }
    return true;
  }

  Future<String?> createOpenAIAssistant(String vectorStoreId, List<String> fileIds, apiKey) async {
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
        "instructions": "You can retrieve transcript information from a vector store. No need to cite sources, and please use complete sentences rather then bullet points. Respond in plain text.",
        "model": currentOpenAIModel,
        "tools": [
          {"type": "file_search"},
          {"type": "code_interpreter"},
        ],
        "tool_resources": {
          "file_search": {
            "vector_store_ids": [vectorStoreId]
          },
          "code_interpreter": {
            "file_ids": fileIds
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      debugPrint("✅ Assistant created: ${jsonResponse["id"]}");
      return jsonResponse["id"];  // Return Assistant ID
    } else {
      debugPrint("❌ Assistant creation failed: ${response.body}");
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
      debugPrint("✅ Thread created: ${jsonResponse["id"]}");
      return jsonResponse["id"];
    } else {
      debugPrint("❌ Thread creation failed: ${response.body}");
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
      debugPrint("✅ Run created: ${jsonResponse["id"]}");
      return jsonResponse["id"];
    } else {
      debugPrint("❌ Failed to run assistant: ${response.body}");
      return null;
    }
  }

  Future<String?> getAssistantResponseInBackground(String threadId, String runId, String apiKey) async {
    return compute(getAssistantResponseIsolate, {"threadId": threadId, "runId": runId, "apiKey": apiKey});
  }

  Future<String?> getAssistantResponseIsolate(Map<String, String> params) async {
    String threadId = params["threadId"]!;
    String runId = params["runId"]!;
    String apiKey = params["apiKey"]!;

    return await getAssistantResponse(threadId, runId, apiKey);
  }

  Future<String?> getAssistantResponse(String threadId, String runId, apiKey) async {
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/runs/$runId");
    int maxAttempts = 5; // Limit retries
    int attempt = 0;

    while (attempt < maxAttempts) {
      // Poll at an interval => on separate thread to prevent blocking the UI
      await Future.delayed(Duration(seconds: 3));
      attempt++;

      var response = await http.get(url, headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        "OpenAI-Beta" : "assistants=v2"
      });

      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      String status = jsonResponse["status"];

      if (status == "completed") {
        break; // Exit loop when assistant has finished processing
      } else if (status == "failed" || status == "cancelled") {
        debugPrint("❌ Assistant run failed: $jsonResponse");
        return null;
      }
    }

    // Fetch latest messages in the thread to get assistant's response
    return getLatestAssistantMessage(threadId, apiKey);
  }

  Future<String?> getLatestAssistantMessage(String threadId, apiKey) async {
    debugPrint("Fetching latest assistant response on thread with ID $threadId");
    var url = Uri.parse("https://api.openai.com/v1/threads/$threadId/messages");

    var response = await http.get(url, headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
      "OpenAI-Beta" : "assistants=v2"
    });

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var messages = jsonResponse["data"];

      for (var message in messages.reversed) { // Read messages from newest to oldest
        if (message["role"] == "assistant") {
          String textResponse = message["content"][0]["text"]["value"];
          return cleanResponse(textResponse);
        }
      }
    } else {
      debugPrint("❌ Failed to fetch messages: ${response.body}");
    }

    return null;
  }

  // Helper function to remove unwanted characters
  String cleanResponse(String response) {
    // Remove source citations
    response = response.replaceAll(RegExp(r'【\d+:\d+†source】'), '').trim();
    // Remove unwanted characters and return
    return response.replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '').trim();
  }
}
