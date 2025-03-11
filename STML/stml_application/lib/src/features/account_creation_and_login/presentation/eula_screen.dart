import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/registration_screen.dart';

class EulaScreen extends StatefulWidget {
  @override
  _EulaScreenState createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("End User License Agreement")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  "End User License Agreement (EULA)\n\n"
                  "By using this app, you agree to the following terms and conditions...\n"
                  "1. You must not misuse the app.\n"
                  "2. We collect and process some user data as per our privacy policy.\n"
                  "3. The app is provided as-is without any warranties.\n\n"
                  "Please read the full terms before proceeding.",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                    });
                  },
                ),
                Expanded(child: Text("I have read and agree to the terms.")),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isChecked
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationScreen()),
                      );
                    }
                  : null, // Button is disabled until checked
              child: Text("Agree & Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
