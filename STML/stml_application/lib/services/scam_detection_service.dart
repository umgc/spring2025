// Purpose: Scam detection service to check for potential scam phrases in the notes.
import 'package:memoryminder/services/scam_detection_ai_service.dart';
import 'package:memoryminder/src/database/transcript_database.dart';

class ScamDetectionService {
  final TranscriptDatabaseHelper _transcriptDatabaseHelper;
  final ChatGptService _chatGptService = ChatGptService();
  
  // Constructor with an optional parameter to initialize _transcripted notes
  ScamDetectionService({TranscriptDatabaseHelper? transcriptDatabaseHelper})
      : _transcriptDatabaseHelper = transcriptDatabaseHelper ?? TranscriptDatabaseHelper();

  // Function to get all notes from the database
  Future<List<Map<String, dynamic>>> getAllNotes() async {
    return await _transcriptDatabaseHelper.getAllNotes();
  }

  // Function to check for scam phrases in the notes
  Future<Map<int, String>> checkPhraseInNotes() async {
    List<Map<String, dynamic>> notes = await getAllNotes();
    Map<int, String> scamNotes = {}; // Store all detected scam notes

    for (var note in notes) {
      if (note['note'] != null) {
        // Construct the AI question to check for scam phrases
        String aiQuestion = "Reply with only 'yes' or 'no'. Given the following scam phrases: <<What’s wrong with my iPad or computer, What do you need me to do, How much does it cost, What did I do wrong, What do I need to pay, How much do I need to send>> Does this seem like a scam? <<Note: ${note['note']}>>";

        print('AI question to console: $aiQuestion');

        // Get the response from the AI service
        String response = await _chatGptService.sendMessage(aiQuestion);
        print('The answer of ChatGPT: $response');

        // If the response is 'yes', add the note to the scamNotes map
        if (response.trim().toLowerCase() == "yes") {
          String phrase = "Potential scam detected in the note: ${note['note']}";
          scamNotes[note['id']] = phrase;
        }
      }
    }

    // Return the scam notes or a message indicating no scams were detected
    return scamNotes.isEmpty ? {0: "No scams detected"} : scamNotes;
  }

  // Function to get all notes from the database
  Future<List<Map<String, dynamic>>> fetchAllNotes() async {
    final db = await _transcriptDatabaseHelper.database;
    return await db.query('transcribed_notes');
  }
}
