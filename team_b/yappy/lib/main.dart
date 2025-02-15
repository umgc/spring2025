import 'package:flutter/material.dart';
import 'package:yappy/logout.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/login_page.dart';
// Correct import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: const LoginPage() 
      //home: const HomePage(),
      // home: const SignUpPage(), 
      //home: const LogoutPage()

    );
  }
}