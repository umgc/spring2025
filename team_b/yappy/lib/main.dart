import 'package:flutter/material.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:yappy/env.dart';
import 'package:yappy/services/file_handler.dart';
import 'package:yappy/services/openai_helper.dart';

// Create a global instance of DatabaseHelper
final DatabaseHelper dbHelper = DatabaseHelper();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  OpenAI.apiKey = Env.apiKey;
  await dbHelper.database;
  final fileHandler = FileHandler();
  // await fileHandler.copyAssetToLocalStorage('assets/test_document.txt', 'test_document.txt');
  await fileHandler.copyAssetToLocalStorage('assets/sample_mechanic_transcript.txt', 'sample_mechanic_transcript.txt');
  await fileHandler.copyAssetToLocalStorage('assets/sample_medical_transcript.txt', 'sample_medical_transcript.txt');
  await fileHandler.copyAssetToLocalStorage('assets/sample_restaurant_order_transcript.txt', 'sample_restaurant_order_transcript.txt');
  // await fileHandler.moveFileToDatabase(dbHelper, 'test_document.txt', 1);
  var openAIService = OpenAIHelper();
  openAIService.summarizeTranscription();
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