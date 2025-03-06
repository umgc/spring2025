import 'package:dart_openai/dart_openai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yappy/services/file_handler.dart';

enum Industry { restaurant, medical, mechanic }
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
  
  Future<String> summarizeTranscription(Industry industry, String transcriptId) async {
    // TODO: remove after testing
    FileHandler fileHandler = FileHandler();
    String transcript = await fileHandler.loadTextFile('${(await getApplicationDocumentsDirectory()).path}/sample_restaurant_order_transcript.txt');
    // String transcript = await fileHandler.loadTextFile('/data/user/0/com.spring2025.yappy/app_flutter/sample_restaurant_order_transcript.txt');
    // TODO: ---

    String contextPrompt;
    switch (industry) {
      case Industry.restaurant:
        contextPrompt = restaurantContextPrompt;
        break;
      case Industry.medical:
        contextPrompt = medicalContextPrompt;
        break;
      case Industry.mechanic:
        contextPrompt = mechanicContextPrompt;
        break;
    }

    String fullPromptToSend = contextPrompt + transcript;
    print(fullPromptToSend);

    List<OpenAIChatCompletionChoiceMessageModel> messages = [
      OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user, content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(fullPromptToSend)])
    ];

    final completion = await OpenAI.instance.chat
        .create(model: "gpt-4o-mini", messages: messages);

    print(completion.choices[0].message.content);
    return completion.choices[0].message.content.toString();
  }
}