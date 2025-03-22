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
            // EULA Text inside a Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  "Welcome to MemoryMinder, your tool for managing tasks, medical information, and more. Please read this End User License Agreement (EULA) carefully before using the app. By using the app, you agree to be bound by the terms and conditions of this EULA.\n"
                  "1. License: MemoryMinder grants you a revocable, non-exclusive, non-transferable, limited license to download, install, and use the app strictly in accordance with the terms of this EULA.\n"
                  "2. Restrictions: You agree not to, and you will not permit others to: a) license, sell, rent, lease, assign, distribute, transmit, host, outsource, disclose, or otherwise commercially exploit the app.\n"
                  "3. Modifications: MemoryMinder reserves the right to modify, suspend or discontinue, temporarily or permanently, the app or any service to which it connects, with or without notice and without liability to you.\n"
                  "4. Termination: This EULA shall remain in effect until terminated by you or MemoryMinder. Your rights under this license will terminate automatically without notice from MemoryMinder if you fail to comply with any term(s) of this EULA.\n"
                  "Please read the full terms before proceeding.",
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Centered Checkbox and Button
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Center the checkbox horizontally
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                        child: Text("I have read and agree to the terms.")),
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
                    child: Text(
                      "Agree & Continue",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 2, 63, 129),
                      padding:
                          EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
