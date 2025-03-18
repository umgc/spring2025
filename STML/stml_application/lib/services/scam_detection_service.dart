import 'package:memoryminder/src/database/transcript_database.dart';

class ScamDetectionService {
  final TranscriptDatabaseHelper _transcriptDatabaseHelper;

  // Constructor with an optional parameter to initialize _transcripted notes
  ScamDetectionService({TranscriptDatabaseHelper? transcriptDatabaseHelper})
      : _transcriptDatabaseHelper = transcriptDatabaseHelper ?? TranscriptDatabaseHelper();

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    return await _transcriptDatabaseHelper.getAllNotes();
  }

  Future<Map<int,String>> checkPhraseInNotes() async {
    final List<String> phrases = [
      "What’s wrong with my iPad or computer",
      "What do you need me to do?",
      "How much does it cost?",
      "What did I do wrong?",
      "What do I need to pay?",
      "How much do I need to send?"
    ];
    List<Map<String, dynamic>> notes = await getAllNotes();
    for (var note in notes) {
      if (note['note'] != null) {
        for (var phrase in phrases) {
          if (note['note'].toString().contains(phrase)) {
            return {note['id']: phrase};
          }
        }
      }
    }
    return {0:""};
  }

  Future<String> getNoteById(int id) async {
    Map<String, dynamic> note = await _transcriptDatabaseHelper.getNote(id);
    return note.toString();
  }
}
