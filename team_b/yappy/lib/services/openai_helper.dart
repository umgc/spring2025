import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yappy/services/file_handler.dart';

class OpenAIHelper {    
  final List<Map<String, String>> messages = [];
  // TODO: Create an ephemeral session for the user instead of a hardcoded key

  final String restaurantContextPrompt =
      '''You are a restaurant assistant.  Take the following audio transcript of a waiter taking patrons' orders and generate a summary of patrons' orders at a restaurant.  There may be up to 10 speakers in the conversation.  Different speakers' voices are indicated by "spk_0", "spk_1", "spk_2" or up to "spk_9".  You must separate out different speakers' orders and refer to them using using "Seat 1", "Seat 2", "Seat 3", etc.
        Example format:

        Seat 1: Hamburger, hold the lettuce, fries, Diet Dr. Pepper.

        Seat 2: Caesar salad, iced tea.

        Audio Transcript:
      ''';

  // TODO: Update prompt
  final String mechanicContextPrompt =
    '''You are a restaurant assistant.  Take the following audio transcript of a waiter taking patrons' orders and generate a summary of patrons' orders at a restaurant.  There may be up to 10 speakers in the conversation.  Different speakers' voices are indicated by "spk_0", "spk_1", "spk_2" or up to "spk_9".  You must separate out different speakers' orders and refer to them using using "Seat 1", "Seat 2", "Seat 3", etc.
      Example format:

      Seat 1: Hamburger, hold the lettuce, fries, Diet Dr. Pepper.

      Seat 2: Caesar salad, iced tea.

      Audio Transcript:
    ''';

  // TODO: Update prompt
  final String medicalContextPrompt =
    '''You are a restaurant assistant.  Take the following audio transcript of a waiter taking patrons' orders and generate a summary of patrons' orders at a restaurant.  There may be up to 10 speakers in the conversation.  Different speakers' voices are indicated by "spk_0", "spk_1", "spk_2" or up to "spk_9".  You must separate out different speakers' orders and refer to them using using "Seat 1", "Seat 2", "Seat 3", etc.
      Example format:

      Seat 1: Hamburger, hold the lettuce, fries, Diet Dr. Pepper.

      Seat 2: Caesar salad, iced tea.

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