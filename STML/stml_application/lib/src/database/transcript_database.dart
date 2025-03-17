import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranscriptDatabaseHelper {
  static final TranscriptDatabaseHelper _instance = TranscriptDatabaseHelper._internal();
  static Database? _database;

  factory TranscriptDatabaseHelper() => _instance;

  TranscriptDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'transcribed_notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE transcribed_notes ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "note TEXT,"
          "source TEXT,"
          "date TEXT,"
          "create_time TEXT"
          ")",
        );

        // sample notes for testing/demo
        await db.insert('transcribed_notes', {
          'note': 'It is great news that I won the lottery and I am ready to make the payment needed to release the reward. How much do I need to send? Also how can I send the payments to you',
          'source': 'Mic recording',
          'date': '2025-03-12',
          'create_time': '10:00 AM'
        });
      },
    );
  }

  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('transcribed_notes', note);
  }

  Future<List<Map<String, dynamic>>> getAllNotes() async {
    final db = await database;
    return await db.query('transcribed_notes');
  }

Future<Map<String, dynamic>> getNote(int id) async {
  final db = await database;
  // Query the 'transcribed_notes' table and filter by 'id'
  final result = await db.query(
    'transcribed_notes',
    where: 'id = ?', // column name for the id in the table
    whereArgs: [id], // The value of the id to filter by
    limit: 1, // Ensure only one result is returned
  );

  if (result.isNotEmpty) {
    // Return the first item in the result list
    return result.first;
  } else {
    // Return an empty map or handle the case when no item is found
    return {};
  }
}
 

  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await database;
    return await db.update('transcribed_notes', note, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('transcribed_notes', where: 'id = ?', whereArgs: [id]);
  }
}
