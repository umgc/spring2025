import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'yappy_database.db');

    // Check if the database already exists
    bool exists = await databaseExists(path);

    if (!exists) {
      // Copy the database from assets if one doesn't exist on the device's filesystem
      try {
        ByteData data = await rootBundle.load('assets/yappy_database.db');
        List<int> bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
      } catch (e) {
        // Can create logging function in later task if wanted
        print('Error copying database: $e');
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        // Check if the tables exist and create them if they don't
        await _createTablesIfNotExists(db);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tables if needed
    await _createTablesIfNotExists(db);
  }

  Future<void> _createTablesIfNotExists(Database db) async {
    // Create Users table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT,
        password TEXT, 
        role TEXT
      )
    ''');

    // Create Vehicle table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Vehicle (
        vehicle_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        vehicle_make TEXT,
        vehicle_model TEXT,
        vehicle_year INTEGER,
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
      )
    ''');

    // Create Transcript table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Transcript (
        transcript_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        transcript_text_data TEXT,
        transcript_timestamp DATETIME,
        transcript_ai_response TEXT,  -- Added transcript_ai_response column
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
      )
    ''');

    // Create VehicleMaintenance table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS VehicleMaintenance (
        maintenance_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transcript_id INTEGER,
        user_id INTEGER,
        vehicle_id INTEGER,
        vehicle_diagnosis_description TEXT,
        vehicle_required_parts TEXT,
        FOREIGN KEY (transcript_id) REFERENCES Transcript(transcript_id),
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id)
      )
    ''');

    // Create SpecialRequest table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SpecialRequest (
        special_request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        special_request_description TEXT
      )
    ''');

    // Create MenuItem table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS MenuItem (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        special_request_id INTEGER,
        item_name TEXT,
        item_description TEXT,
        item_price REAL,
        seat_position INTEGER,
        FOREIGN KEY (special_request_id) REFERENCES SpecialRequest(special_request_id)
      )
    ''');

    // Create RestaurantOrder table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS RestaurantOrder (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        transcript_id INTEGER,
        order_status TEXT,
        order_total_cost REAL,
        FOREIGN KEY (transcript_id) REFERENCES Transcript(transcript_id)
      )
    ''');

    // Create OrderItems table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS OrderItems (
        order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        item_id INTEGER,
        order_item_qty INTEGER,
        FOREIGN KEY (order_id) REFERENCES RestaurantOrder(order_id),
        FOREIGN KEY (item_id) REFERENCES MenuItem(item_id)
      )
    ''');

    // Create Patient table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Patient (
        patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        patient_first_name TEXT,
        patient_last_name TEXT,
        patient_phone TEXT,
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
      )
    ''');

    // Create DoctorVisit table if it doesn't exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS DoctorVisit (
        visit_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        transcript_id INTEGER,
        patient_id INTEGER,
        doctor_visit_symptoms TEXT,
        doctor_visit_diagnosis TEXT,
        FOREIGN KEY (user_id) REFERENCES Users(user_id),
        FOREIGN KEY (transcript_id) REFERENCES Transcript(transcript_id),
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
      )
    ''');
  }

  // Users table methods
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('Users');
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('Users', user);
  }

  Future<int> updateUser(Map<String, dynamic> user) async {
    final db = await database;
    int id = user['user_id'];
    return await db.update('Users', user, where: 'user_id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('Users', where: 'user_id = ?', whereArgs: [id]);
  }

  // Vehicle table methods
  Future<int> insertVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    return await db.insert('Vehicle', vehicle);
  }

  Future<int> updateVehicle(Map<String, dynamic> vehicle) async {
    final db = await database;
    int id = vehicle['vehicle_id'];
    return await db.update('Vehicle', vehicle, where: 'vehicle_id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('Vehicle', where: 'vehicle_id = ?', whereArgs: [id]);
  }

  // VehicleMaintenance table methods
  Future<int> insertVehicleMaintenance(Map<String, dynamic> maintenance) async {
    final db = await database;
    return await db.insert('VehicleMaintenance', maintenance);
  }

  Future<int> updateVehicleMaintenance(Map<String, dynamic> maintenance) async {
    final db = await database;
    int id = maintenance['maintenance_id'];
    return await db.update('VehicleMaintenance', maintenance, where: 'maintenance_id = ?', whereArgs: [id]);
  }

  Future<int> deleteVehicleMaintenance(int id) async {
    final db = await database;
    return await db.delete('VehicleMaintenance', where: 'maintenance_id = ?', whereArgs: [id]);
  }

  // Transcript table methods
  Future<int> insertTranscript(Map<String, dynamic> transcript) async {
    final db = await database;
    return await db.insert('Transcript', transcript);
  }

  Future<int> updateTranscript(Map<String, dynamic> transcript) async {
    final db = await database;
    int id = transcript['transcript_id'];
    return await db.update('Transcript', transcript, where: 'transcript_id = ?', whereArgs: [id]);
  }

  Future<int> deleteTranscript(int id) async {
    final db = await database;
    return await db.delete('Transcript', where: 'transcript_id = ?', whereArgs: [id]);
  }

  // RestaurantOrder table methods
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    return await db.insert('RestaurantOrder', order);
  }

  Future<int> updateOrder(Map<String, dynamic> order) async {
    final db = await database;
    int id = order['order_id'];
    return await db.update('RestaurantOrder', order, where: 'order_id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('RestaurantOrder', where: 'order_id = ?', whereArgs: [id]);
  }

  // OrderItems table methods
  Future<int> insertOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    return await db.insert('OrderItems', orderItem);
  }

  Future<int> updateOrderItem(Map<String, dynamic> orderItem) async {
    final db = await database;
    int id = orderItem['order_item_id'];
    return await db.update('OrderItems', orderItem, where: 'order_item_id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrderItem(int id) async {
    final db = await database;
    return await db.delete('OrderItems', where: 'order_item_id = ?', whereArgs: [id]);
  }

  // MenuItem table methods
  Future<List<Map<String, dynamic>>> getMenuItems() async {
    final db = await database;
    return await db.query('MenuItem');
  }

  Future<int> insertMenuItem(Map<String, dynamic> menuItem) async {
    final db = await database;
    return await db.insert('MenuItem', menuItem);
  }

  Future<int> updateMenuItem(Map<String, dynamic> menuItem) async {
    final db = await database;
    int id = menuItem['item_id'];
    return await db.update('MenuItem', menuItem, where: 'item_id = ?', whereArgs: [id]);
  }

  Future<int> deleteMenuItem(int id) async {
    final db = await database;
    return await db.delete('MenuItem', where: 'item_id = ?', whereArgs: [id]);
  }

  // SpecialRequest table methods
  Future<int> insertSpecialRequest(Map<String, dynamic> specialRequest) async {
    final db = await database;
    return await db.insert('SpecialRequest', specialRequest);
  }

  Future<int> updateSpecialRequest(Map<String, dynamic> specialRequest) async {
    final db = await database;
    int id = specialRequest['special_request_id'];
    return await db.update('SpecialRequest', specialRequest, where: 'special_request_id = ?', whereArgs: [id]);
  }

  Future<int> deleteSpecialRequest(int id) async {
    final db = await database;
    return await db.delete('SpecialRequest', where: 'special_request_id = ?', whereArgs: [id]);
  }

  // DoctorVisit table methods
  Future<List<Map<String, dynamic>>> getDoctorVisits() async {
    final db = await database;
    return await db.query('DoctorVisit');
  }

  Future<int> insertDoctorVisit(Map<String, dynamic> doctorVisit) async {
    final db = await database;
    return await db.insert('DoctorVisit', doctorVisit);
  }

  Future<int> updateDoctorVisit(Map<String, dynamic> doctorVisit) async {
    final db = await database;
    int id = doctorVisit['visit_id'];
    return await db.update('DoctorVisit', doctorVisit, where: 'visit_id = ?', whereArgs: [id]);
  }

  Future<int> deleteDoctorVisit(int id) async {
    final db = await database;
    return await db.delete('DoctorVisit', where: 'visit_id = ?', whereArgs: [id]);
  }

  // Patient table methods
  Future<int> insertPatient(Map<String, dynamic> patient) async {
    final db = await database;
    return await db.insert('Patient', patient);
  }

  Future<int> updatePatient(Map<String, dynamic> patient) async {
    final db = await database;
    int id = patient['patient_id'];
    return await db.update('Patient', patient, where: 'patient_id = ?', whereArgs: [id]);
  }

  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete('Patient', where: 'patient_id = ?', whereArgs: [id]);
  }

  // Specific use-case Query functions

  // Given DoctorVisit visit_id, get doctor_visit_symptoms and doctor_visit_diagnosis
  Future<Map<String, dynamic>?> getDoctorVisitById(int visitId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'DoctorVisit',
      columns: ['doctor_visit_symptoms', 'doctor_visit_diagnosis'],
      where: 'visit_id = ?',
      whereArgs: [visitId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Given DoctorVisit patient_id, get doctor_visit_symptoms and doctor_visit_diagnosis
  Future<List<Map<String, dynamic>>> getDoctorVisitsByPatientId(int patientId) async {
    final db = await database;
    return await db.query(
      'DoctorVisit',
      columns: ['doctor_visit_symptoms', 'doctor_visit_diagnosis'],
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
  }

  // Given VehicleMaintenance maintenance_id, get vehicle_diagnosis_description and vehicle_required_parts
  Future<Map<String, dynamic>?> getVehicleMaintenanceById(int maintenanceId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'VehicleMaintenance',
      columns: ['vehicle_diagnosis_description', 'vehicle_required_parts'],
      where: 'maintenance_id = ?',
      whereArgs: [maintenanceId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Given Vehicle vehicle_id, get vehicle_make, vehicle_model, and vehicle_year
  Future<Map<String, dynamic>?> getVehicleById(int vehicleId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Vehicle',
      columns: ['vehicle_make', 'vehicle_model', 'vehicle_year'],
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // Given Vehicle user_id, get all vehicle_id with given user_id
  Future<List<int>> getVehicleIdsByUserId(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Vehicle',
      columns: ['vehicle_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((result) => result['vehicle_id'] as int).toList();
  }
  // Get all transcript_id with given user_id
  Future<List<int>> getTranscriptIdsByUserId(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Transcript',
      columns: ['transcript_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((result) => result['transcript_id'] as int).toList();
  }

  // Get all maintenance_id with given user_id
  Future<List<int>> getMaintenanceIdsByUserId(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'VehicleMaintenance',
      columns: ['maintenance_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.map((result) => result['maintenance_id'] as int).toList();
  }

  // Get all item_id from order items with matching given order_id
  Future<List<int>> getItemIdsByOrderId(int orderId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'OrderItems',
      columns: ['item_id'],
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return results.map((result) => result['item_id'] as int).toList();
  }
}