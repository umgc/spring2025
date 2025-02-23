import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'database_helper.dart';
import 'dart:io'; // For manual correction via console input (optional)

class OrderService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _recognizedText = "";

  Future<String> captureSpeechInput() async {
    bool available = await _speech.initialize();
    if (!available) {
      throw Exception("Speech recognition not available");
    }

    Completer<String> completer = Completer<String>(); // To handle async speech capture

    await _speech.listen(onResult: (result) {
      _recognizedText = result.recognizedWords; // Store recognized words
    });

    await Future.delayed(Duration(seconds: 3)); // Wait for speech input
    await _speech.stop();

    String correctedText = await manualCorrection(_recognizedText);
    completer.complete(correctedText); // Return corrected text
    return completer.future;
  }

  Future<String> manualCorrection(String recognizedText) async {
    print("Recognized text: $recognizedText");
    print("Enter corrected text (or press Enter to keep original):");
    String? correctedText = stdin.readLineSync();
    return correctedText != null && correctedText.isNotEmpty ? correctedText : recognizedText;
  }

  Future<List<Map<String, dynamic>>> extractMenuItems(String speechText) async {
    List<Map<String, dynamic>> menuItems = await _dbHelper.getMenuItems();
    List<Map<String, dynamic>> extractedItems = [];

    for (var item in menuItems) {
      String itemName = item['name'].toString().toLowerCase();
      if (speechText.toLowerCase().contains(itemName)) {
        extractedItems.add(item);
      }
    }
    
    return extractedItems;
  }

  Future<Map<String, dynamic>> processOrder(String speechText) async {
    List<Map<String, dynamic>> orderedItems = await extractMenuItems(speechText);
    if (orderedItems.isEmpty) {
      throw Exception("No valid menu items found in the speech input");
    }

    Map<String, dynamic> orderData = {
      'items': orderedItems,
      'timestamp': DateTime.now().toIso8601String()
    };

    await _dbHelper.insertOrder(orderData);
    return orderData;
  }
}
