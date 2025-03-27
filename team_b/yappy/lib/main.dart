import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:yappy/env.dart';
import './toast_widget.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

// Create a global instance of DatabaseHelper
final DatabaseHelper dbHelper = DatabaseHelper();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
late SharedPreferences preferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  preferences = await SharedPreferences.getInstance();

  // Load the theme preference from SharedPreferences
  final isDarkMode = preferences.getBool('toggle_setting') ?? false;

  // Env file setup for local development
  String apiKey = Env.apiKey;
  if (apiKey.isNotEmpty) {
    OpenAI.apiKey = apiKey;
    await preferences.setString('openai_api_key', apiKey);
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
            content: Text('Please add a valid OpenAI API key via the Settings menu.'),
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

  // Run the app and initialize ThemeProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..toggleTheme(isDarkMode), // Initialize with saved theme
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Yappy',
      theme: themeProvider.themeData, // Apply theme based on provider
      darkTheme: ThemeProvider.darkTheme, // Provide dark theme separately
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light, // Set theme mode based on isDarkMode
      home: HomePage(),
      builder: (context, child) {
        // Wrap every screen with ToastWidget
        return ToastWidget(child: child ?? Container());
      },
    );
  }
}
