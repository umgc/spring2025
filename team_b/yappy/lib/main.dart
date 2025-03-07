import 'package:flutter/material.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:yappy/env.dart';
import './toast_widget.dart';

// Create a global instance of DatabaseHelper
final DatabaseHelper dbHelper = DatabaseHelper();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Env file setup for local development
  String apiKey = Env.apiKey;
  if (apiKey.isNotEmpty) {
    OpenAI.apiKey = apiKey;
    print('Env API Key found and set');
  } else {
    print('Env API Key not found');
  }

  await dbHelper.database;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Shows dialog requesting an OpenAI API key if not set
    if (apiKey.isEmpty) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('OpenAI API Key Required'),
            content: Text('Please add an OpenAI API key via the Settings menu.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Your App',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      builder: (context, child) {
        // Wrap every screen with ToastWidget
        return ToastWidget(child: child ?? Container());
      },
    );
  }
}