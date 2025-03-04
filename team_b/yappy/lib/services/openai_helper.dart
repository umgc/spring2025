import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:path_provider/path_provider.dart';
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

  // TODO: needs to take in industry name and transcript ID from Sherpa to then pull from DB
  Future<String> summarizeTranscription() async {
    // OpenAI.apiKey = Env.apiKey; // currently handled in main.dart
    // File storedFile = File('${(await getApplicationDocumentsDirectory()).path}/sample_restaurant_order_transcript.txt');

    FileHandler fileHandler = FileHandler();
    String transcript = await fileHandler.loadTextFile('${(await getApplicationDocumentsDirectory()).path}/sample_restaurant_order_transcript.txt');
    print(transcript);

    String restaurantPromptToSend = restaurantContextPrompt + transcript;

    // ignore: avoid_print TODO: remove
    print(restaurantPromptToSend);

    List<OpenAIChatCompletionChoiceMessageModel> messages = [
      OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user, content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(restaurantPromptToSend)])
    ];

    final completion = await OpenAI.instance.chat
        .create(model: "gpt-4o-mini", messages: messages);

    // ignore: avoid_print TODO: remove
    print(completion.choices[0].message.content);
    return completion.choices[0].message.content.toString();
  }
}