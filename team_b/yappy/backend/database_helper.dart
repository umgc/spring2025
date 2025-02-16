import 'dart:io';
import 'package:path/path.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseHelper {
  static final String dbName = "yappy.db";
  static late Database _database;

  static Future<void> initDatabase() async {
    // Use the current directory for the database file
    final String dbPath = Directory.current.path;
    final String fullPath = join(dbPath, dbName);

    _database = sqlite3.open(fullPath);

    _database.execute('''
      CREATE TABLE IF NOT EXISTS menu (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
      );
    ''');

    _database.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        items TEXT NOT NULL,
        timestamp TEXT NOT NULL
      );
    ''');

    print("Database initialized at: $fullPath");
  }

  static Database getDatabase() {
    return _database;
  }
}
