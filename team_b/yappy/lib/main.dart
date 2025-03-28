import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import './home_page.dart';
import './services/database_helper.dart';
import './env.dart';
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
  String awsAccessKey = Env.awsAccessKey;
  String awsSecretKey = Env.awsSecretKey;
  String awsRegion = Env.awsRegion;
  if (apiKey.isNotEmpty) {
    OpenAI.apiKey = apiKey;
    await preferences.setString('openai_api_key', apiKey);
  }
  if (awsRegion.isNotEmpty && awsAccessKey.isNotEmpty && awsSecretKey.isNotEmpty)
  {
    await preferences.setString('aws_access_key', awsAccessKey);
    await preferences.setString('aws_secret_key', awsSecretKey);
    await preferences.setString('aws_region', awsRegion);
    await preferences.setBool('awsAvailable', true);
  }
  else
  {
    await preferences.setBool('awsAvailable', false);
  }

  if (Platform.isLinux || Platform.isWindows)
  {
    sqfliteFfiInit();   // Init ffi loader based on platform.
    databaseFactory = databaseFactoryFfi;
  }

  await dbHelper.database;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Shows dialog requesting a API keys if not set
    if (apiKey.isEmpty) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('API Keys Required'),
            content: Text('Please add valid API keys for OpenAI and AWS via the Settings menu.'),
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
