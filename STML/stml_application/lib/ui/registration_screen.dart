/*
Author: Eyerusalme (Jerry)
*/
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'onboardingScreen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  bool _useFaceID = true;
  bool _isButtonActive = false;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    print("Directory path: ${directory.path}");
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_data.txt');
  }

  Future<File> writeUserData(String data) async {
    final file = await _localFile;
    // Debugging statement
    print("Writing data to: ${file.path}");
    // Write the data to the file.
    return file.writeAsString('$data\n', mode: FileMode.append);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF880E4F),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0x440000), // Set appbar background color
        elevation: 0.0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('Registration', style: TextStyle(color: Colors.black54)),
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
                  onChanged: () {
                   setState(()  {
                     _isButtonActive = _firstNameController.text.isNotEmpty &&
                         _lastNameController.text.isNotEmpty &&
                         _emailController.text.isNotEmpty;
                    });
                  },
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
                      ),                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Use Biometric Authentication"),
                        Switch(
                          value: _useFaceID,
                          onChanged: (value) {
                            setState(() {
                              _useFaceID = value;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isButtonActive
                          ? () async {
                        if (_formKey.currentState!.validate()) {
                          String userData =
                              '${_firstNameController.text}, ${_lastNameController.text}, ${_emailController.text}, ${_useFaceID.toString()}';
                          print("User Data: $userData");
                          await writeUserData(userData);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => OnboardingScreen()));
                        }

                      }
                          : null,
                      child: Text("Create Account"),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: Text("Privacy Policy"),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text("Terms and Conditions"),
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
      )
    );
  }
}
