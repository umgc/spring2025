import 'dart:convert';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yappy/main.dart';
import 'package:assistant_openai/common/ai/models/newagentmodel.dart';
import 'package:assistant_openai/openaiassistant.dart';
import 'package:assistant_openai/common/ai/models/ThreadModificationModel.dart';


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

  Future<String> startTranscriptChatAssistant() async {
    // TODO: change orgID. accept from the user in Settings/preferences along with key? or just pass empty string?
    debugPrint(preferences.getString('openai_api_key'));
    var client = OpenAIAssistant(apiKey: preferences.getString('openai_api_key')!, organizationID: 'Zander Forsythe');

    // TODO: likely need to pull all transcripts from the database that have current industry value

    // TODO: create a vector store that contains each transcript

    ///CREATE A VARIABLE WITH NEW ASSISTANT OBJECT
    var newAssistant = NewAssistantModel(
        name: "Yappu",
        description: "Transcript Analysis Chatbot",
        instructions: "You are a helpful assistant who can analyze the contents of transcript text documents and provide insights for user questions.",
        model: "gpt-4o-mini",
        tools: [
          Tool(type: "file_search"),
          Tool(type: "code_interpreter")
        ],
        fileIds: ['sample_restaurant_order_transcript.txt'], // TODO: populate with vector store IDs
    );

    ///USE THE CLIENT TO ACCESS THE ASSISTANT CREATE MODULE AND PARSE THE NEW ASSISTANT OBJECT YOU CREATED
    // var assistant = await client.assistant.create(newAssistant);
    var assistant = await openAIAssistant(newAssistant.toJson(), "assistants", preferences.getString('openai_api_key')!);

    ///YOU GET BACK THE FOLLOWING VALUES FROM THE RESPONSE
    debugPrint(assistant!.name);
    debugPrint(assistant.model);
    debugPrint(assistant.instructions);
    debugPrint(assistant.tools.toString());
    debugPrint(assistant.fileIds.toString());
    debugPrint(assistant.description);
    debugPrint(assistant.metadata.toString());

    // var thread = await client.threads.createEmptyThread();
    // var threadMessageModel = CreateThreadMessageModel(
    //   role: "user",
    //   content: "What is 2 + 2?",
    //   threadId: "1",
    // );
    // var message = await client.threads.messages.create(threadMessageModel);
    // var run = await client.threads.runs.create("1", newAssistant.name);

    // var messages = await client.threads.messages.list("1", "ascending"); // todo: proper order?
    // for (var msg in messages!.data) { // todo: non-null assumption
    //   debugPrint("${msg.role}: ${msg.content}");
    // }

    return "";
  }

  // TODO: pulled from flutter package implementation because it is out of date
  Future openAIAssistant(Map data, endpoint, apiKey) async{
    var url = Uri.parse('https://api.openai.com/v1/$endpoint');
    var response = await http.post(url,
        body: jsonEncode(data),
        headers: {
          "Authorization" : "Bearer $apiKey",
          "Content-Type" : "application/json; charset=UTF-8",
          "OpenAI-Beta" : "assistants=v2"
        }
    );

    return response;

  }
}