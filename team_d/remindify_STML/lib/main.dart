import 'package:flutter/material.dart';
import 'screens/welcome_page_remindify.dart';

void main() {
  runApp(const STMLApp());
}

class STMLApp extends StatelessWidget {
  const STMLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remindify',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WelcomePage(),
    );
  }
}
