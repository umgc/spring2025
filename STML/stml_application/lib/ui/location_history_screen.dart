// Author: Vincent Galeano
// Edited by: Ben Sutter
// Description: This class allows the user to see a visualization of previous location history

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:memoryminder/src/utils/format_utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:moment_dart/moment_dart.dart';

// Create a model for location entries
class LocationEntry {
  int? id;
  final String address;
  final DateTime startTime;
  DateTime? endTime;

  LocationEntry(
      {this.id, required this.address, required this.startTime, this.endTime});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  static LocationEntry fromMap(Map<String, dynamic> map) {
    return LocationEntry(
      id: map['id'] as int?,
      address: map['address'],
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
    );
  }
}

// Database helper class
class LocationDatabase {
  static final LocationDatabase instance = LocationDatabase._init();

  static Database? _database;

  LocationDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('location_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  address TEXT NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT
)
''');
  }

  Future<int> create(LocationEntry location) async {
    final db = await instance.database;
    final id = await db.insert('locations', location.toMap());
    return id;
  }

  Future<List<LocationEntry>> readAllLocations() async {
    final db = await instance.database;
    final result = await db.query('locations', orderBy: 'startTime DESC');
    return result.map((json) => LocationEntry.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<int> update(LocationEntry location) async {
    final db = await instance.database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }
}

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  _LocationHistoryScreenState createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  List<LocationEntry> locations = [];
  final DateFormat formatter = DateFormat('hh:mm a');
  Timer? _timer; // Declare a Timer variable

  @override
  void initState() {
    super.initState();
    _loadLocations();
    //_startAutoRefresh(); // Start the auto refresh timer
  }

  Future<void> _loadLocations() async {
    locations = await LocationDatabase.instance.readAllLocations();
    setState(() {});
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadLocations(); // Refresh data every second
    });
  }

  String formattedTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period";
  }

  String sanitizeAddress(String address) {
    return address.replaceAll(' ,', ',').replaceAll(', ,', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              const Color(0x00440000), // Set appbar background color
          centerTitle: true,
          title: const Text('Location History',
              style: TextStyle(color: Colors.black54)),
          elevation: 0,
          leading: const BackButton(color: Colors.black54),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _loadLocations,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: locations.isEmpty
                  ? const Center(child: Text("No locations found"))
                  : ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        if (index > 0 && locations[index].endTime == null) {
                          return Container(); // Return an empty container for these items.
                        } else {
                          return Card(
                            color: const Color.fromRGBO(255, 255, 255, 0.75),
                            child: ListTile(
                              leading: Container(
                                height: double.infinity,
                                child: const Icon(Icons.location_on),
                              ),
                              title: Text(
                                  sanitizeAddress(locations[index].address)),
                              subtitle: Text(getTimeStampString(
                                  locations[index].startTime,
                                  locations[index].endTime,
                                  index)),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ),
        ));
  }

  String getTimeStampString(DateTime? start, DateTime? end, int index) {
    if (end != null && FormatUtils.calculateDifferenceInHours(end) == 0) {
      return "${timeago.format(end)} (${this.formattedTime(end)})";
    }

    String formattedDate =
        Moment(start!).format('MMMM Do, YYYY'); // Format the date
    String formattedTime =
        '${this.formattedTime(start)} - ${end != null ? this.formattedTime(end) : 'Now'}';

    return "$formattedDate $formattedTime";
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Make sure to cancel the Timer when the widget is disposed
    super.dispose();
  }
}

void main() => runApp(const MaterialApp(
      home: LocationHistoryScreen(),
    ));
