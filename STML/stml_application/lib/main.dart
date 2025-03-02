import 'package:flutter/material.dart';

void main() {
  runApp(STMLApp());
}

class STMLApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to [STML App]',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Image.asset('assets/welcome_image.png',
                  height: 200), // Add a nice image
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Login Page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Log In',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 15),
              OutlinedButton(
                onPressed: () {
                  // Navigate to Create Account Page
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.blue, width: 2),
                ),
                child: Text('Create Account',
                    style: TextStyle(fontSize: 18, color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
