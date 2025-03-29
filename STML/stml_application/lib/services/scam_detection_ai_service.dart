import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatGptService {

  // Initializes the environment variables by loading them from the `.env` file.
  static Future<void> initialize() async {
    await dotenv.load();
  }
  
  // API key for authentication, retrieved from environment variables.
  // Defaults to 'API_KEY_NOT_FOUND' if not found.
  final String apiKey = dotenv.env['OPEN_AI_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  // OpenAI API endpoint URL, retrieved from environment variables.
  // Defaults to 'API_URL_NOT_FOUND' if not found.
  final String apiUrl = dotenv.env['OPEN_AI_API_URL'] ?? 'API_URL_NOT_FOUND';
  
  // Default constructor for the ChatGptService class.
  ChatGptService();

 // Sends a message to the OpenAI ChatGPT API and returns the response.
  Future<String> sendMessage(String message) async {
    try {
      // Making an HTTP POST request to the OpenAI API.
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message},
          ],
        }),
      );
     // Checking if the response is successful (HTTP 200 OK).
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        // Returning error message if API call fails.
        return "Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      // Returning exception message if an error occurs.
      return "Exception: $e";
    }
  }
}
