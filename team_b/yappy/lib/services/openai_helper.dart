import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:yappy/main.dart';
import 'package:assistant_openai/common/ai/models/newagentmodel.dart';
import 'package:assistant_openai/openaiassistant.dart';
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
        aiResponse: completion.choices[0].message.content.toString());
      return completion.choices[0].message.content.toString();
    } catch (e) {
      rethrow;
    }
  }

  void transcriptChatAssistant() async {
    // TODO: change orgID
    var client = OpenAIAssistant(apiKey: preferences.getString('openai_api_key')!, organizationID: 'Zander Forsythe');

    ///CREATE A VARIABLE WITH NEW ASSISTANT OBJECT
    var newAssistant = NewAssistantModel(
        name: "Yappu",
        description: "Transcript Analysis Chatbot",
        instructions: "You are a helpful assistant who can analyze the contents of transcript text documents and provide insights for user questions.",
        model: "gpt-4o-mini",
        tools: [
          Tool(type: "retrieval"),
          Tool(type: "file-search"),
          Tool(type: "code-interpreter")
        ],
        // TODO: should this say 'fileId' and be a list of them? this list of transcript IDs gets passed in somehow
        fileIds: ['fieldId'],
    );

    ///USE THE CLIENT TO ACCESS THE ASSISTANT CREATE MODULE AND PARSE THE NEW ASSISTANT OBJECT YOU CREATED
    var assistant = await client.assistant.create(newAssistant);

    ///YOU GET BACK THE FOLLOWING VALUES FROM THE RESPONSE
    debugPrint(assistant!.name);
    debugPrint(assistant.model);
    debugPrint(assistant.instructions);
    debugPrint(assistant.tools.toString());
    debugPrint(assistant.fileIds.toString());
    debugPrint(assistant.description);
    debugPrint(assistant.metadata.toString());
  }
}