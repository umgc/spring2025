// ignore_for_file: avoid_print, prefer_const_constructors

/*
Author: Eyerusalme (Jerry)
*/
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emergencyFirstNameController = TextEditingController();
  final TextEditingController _emergencyLastNameController = TextEditingController();
  final TextEditingController _emergencyPhoneController = TextEditingController();
  String _biometricAuth = '';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_data.txt');
  }

  Future<String> readUserData() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      return '';
    }
  }

  Future<File> writeUserData(String data) async {
    final file = await _localFile;
    return file.writeAsString(data);
  }

  Future<void> populateData() async {
    String data = await readUserData();
    List<String> details = data.split(', ');
    if (details.length >= 3) {
      _firstNameController.text = details[0];
      _lastNameController.text = details[1];
      _emailController.text = details[2];
      if (details.length > 4) _phoneController.text = details[4];
      if (details.length > 5) _emergencyFirstNameController.text = details[5];
      if (details.length > 6) _emergencyLastNameController.text = details[6];
      if (details.length > 7) _emergencyPhoneController.text = details[7];
    }
  }

  Future<void> setBiometricAuth() async {
    String data = await readUserData();
    List<String> details = data.split(', ');
    _biometricAuth = details[3];
  }

  @override
  void initState() {
    super.initState();
    setBiometricAuth();
    populateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF880E4F),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0x00440000), // Set appbar background color
        elevation: 0.0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('Profile', style: TextStyle(color: Colors.black54)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email Address'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(labelText: 'Phone Number'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(
                                  r"^(\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4}$")
                              .hasMatch(value)) {
                            return 'Please enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emergencyFirstNameController,
                        decoration:
                            InputDecoration(labelText: 'Emergency First Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the emergency first name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emergencyLastNameController,
                        decoration:
                            InputDecoration(labelText: 'Emergency Last Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the emergency last name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _emergencyPhoneController,
                        decoration: InputDecoration(
                            labelText: 'Emergency Phone Number'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter the emergency phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                String userData =
                                    '${_firstNameController.text}, ${_lastNameController.text}, ${_emailController.text}, $_biometricAuth, ${_phoneController.text}, ${_emergencyFirstNameController.text}, ${_emergencyLastNameController.text}, ${_emergencyPhoneController.text}';
                                await writeUserData(userData);
                                Navigator.pushReplacementNamed(
                                    context, '/homeScreen');
                              }
                            },
                            child: const Text('Save'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
