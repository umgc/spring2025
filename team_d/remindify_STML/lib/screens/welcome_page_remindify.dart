import 'package:flutter/material.dart';
import 'care_recipient_page.dart';
import 'caregiver_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
                'Welcome to Remindify',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'by MemoryCare',
                style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Stay organized, never miss important tasks, and regain control of your daily life with ease.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Image.asset('assets/welcome_image.png', height: 200),
              SizedBox(height: 30),
              Text(
                'How may I help you?',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
              ),
              Text(
                'Select one of the options below to get started',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 15),

              // Care Recipient Button - ""Help me stay on track!""
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CareRecipientPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Help me stay on track!',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              Text('For Care Recipient'),
              SizedBox(height: 30),

              // Caregiver Button - ""I am supporting someone""
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CaregiverPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('I am supporting someone',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              Text('For Caregiver'),
            ],
          ),
        ),
      ),
    );
  }
}
