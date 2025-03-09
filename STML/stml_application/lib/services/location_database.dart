// lib/services/location_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:memoryminder/models/location_entry.dart';

/// Service class for handling location data persistence
class LocationDatabase {
  static final LocationDatabase instance = LocationDatabase._init();
  static Database? _database;

  LocationDatabase._init();

  /// Get database instance, creating if necessary
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locations.db');
    return _database!;
  }

  /// Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE locations (  
        id INTEGER PRIMARY KEY AUTOINCREMENT,  
        address TEXT NOT NULL,  
        startTime TEXT NOT NULL,  
        endTime TEXT  
      )  
    ''');
  }

  /// Create a new location entry
  Future<int> create(LocationEntry location) async {
    final db = await instance.database;
    return await db.insert('locations', location.toMap());
  }

  /// Read a location entry by ID
  Future<LocationEntry?> read(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'locations',
      columns: ['id', 'address', 'startTime', 'endTime'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LocationEntry.fromMap(maps.first);
    }
    return null;
  }

  /// Update an existing location entry
  Future<int> update(LocationEntry location) async {
    final db = await instance.database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  /// Delete a location entry
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all location entries
  Future<List<LocationEntry>> getAllLocations() async {
    final db = await instance.database;
    final result = await db.query('locations', orderBy: 'startTime DESC');
    return result.map((map) => LocationEntry.fromMap(map)).toList();
  }

  /// Get location entries for a specific date range
  Future<List<LocationEntry>> getLocationsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'locations',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime DESC',
    );
    return result.map((map) => LocationEntry.fromMap(map)).toList();
  }

  /// Close the database
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
