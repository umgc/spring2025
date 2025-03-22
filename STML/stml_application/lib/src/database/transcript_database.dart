// This class provides helper methods to interact with the 'transcribed_notes' SQLite database.
// It includes methods to initialize the database, insert, retrieve, update, and delete notes.
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranscriptDatabaseHelper {
  static final TranscriptDatabaseHelper _instance = TranscriptDatabaseHelper._internal();
  static Database? _database;

  factory TranscriptDatabaseHelper() => _instance;

  TranscriptDatabaseHelper._internal();

  // Get the database, initialize if not already done
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'transcribed_notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create the 'transcribed_notes' table
        await db.execute(
          "CREATE TABLE transcribed_notes ("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "note TEXT,"
          "source TEXT,"
          "date TEXT,"
          "create_time TEXT"
          ")",
        );

        // Insert a sample note for testing/demo
        await db.insert('transcribed_notes', {
          'note': 'Potential scam detected in the note: How much does it cost My laptop is not working properly.',
          'source': 'transcribed notes',
          'date': '2025-03-12',
          'create_time': '10:00 AM'
        });
      },
    );
  }

  // Inserts a new note into the 'transcribed_notes' table in the database.
  // This function asynchronously inserts a new record into the 'transcribed_notes'
  // table using the provided map of column names and values.
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('transcribed_notes', note);
  }

  // Retrieves all notes from the 'transcribed_notes' table in the database.
  // This function asynchronously fetches all records from the 'transcribed_notes'
  // table and returns them as a list of maps, where each map represents a row
  // in the table with column names as keys and corresponding values.
  // A `Future` that resolves to a `List` of `Map<String, dynamic>`, where each
  // map contains the data of a single row from the 'transcribed_notes' table.
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
 // Provides methods to update notes in the 'transcribed_notes' table of the database. 
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await database;
    return await db.update('transcribed_notes', note, where: 'id = ?', whereArgs: [id]);
  }
 // Provides methods to delete notes in the 'transcribed_notes' table of the database. 
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('transcribed_notes', where: 'id = ?', whereArgs: [id]);
  }
}
