import 'package:flutter/material.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/services/database_helper.dart';

// Create a global instance of DatabaseHelper
final DatabaseHelper dbHelper = DatabaseHelper();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
// This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}