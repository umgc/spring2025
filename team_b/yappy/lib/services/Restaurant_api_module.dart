import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'database_helper.dart';

class RestaurantAPI {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  Future<void> transcribeAndStoreOrder() async {
    bool available = await _speechToText.initialize();
    if (available) {
      _speechToText.listen(onResult: (result) async {
        if (result.finalResult) {
          await dbHelper.storeTranscript(result.recognizedWords);
        }
      });
    }
  }

  Future<List<int>> getTranscriptIdsByUserId(int userId) async  {
    return await dbHelper.getTranscriptIdsByUserId(userId);
  }

  Future<List<String>> validateMenuItems(String orderText) async {
    List<String> menuItems = await dbHelper.getMenuItems();
    List<String> validItems = [];
    for (var item in menuItems) {
      if (orderText.toLowerCase().contains(item.toLowerCase())) {
        validItems.add(item);
      }
    }
    return validItems;
  }

  Future<void> correctAndStoreOrder(String correctedOrder) async {
    await dbHelper.storeProcessedOrder(correctedOrder);
  }

  Future<List<Map<String, dynamic>>> getOrderHistory() async {
    return await dbHelper.getOrderHistory();
  }
}
