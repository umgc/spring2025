import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'onboarding_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _useBiometric = false;
  bool _isButtonActive = false;

  Future<bool> _authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to register',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      print("Biometric authentication error: $e");
      return false;
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_data.txt');
  }

  Future<File> writeUserData(String data) async {
    final file = await _localFile;
    return file.writeAsString('$data\n', mode: FileMode.append);
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_useBiometric) {
        bool isAuthenticated = await _authenticate();
        if (!isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Biometric authentication failed")));
          return;
        }
      }

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String userData =
            '${_firstNameController.text}, ${_lastNameController.text}, ${_emailController.text}, ${_useBiometric.toString()}';
        await writeUserData(userData);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      } catch (e) {
        print("Firebase Authentication Error: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Registration failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0x440000),
        elevation: 0.0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title:
            const Text('Registration', style: TextStyle(color: Colors.black54)),
      ),
      body: Container(

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
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  onChanged: () {
                    setState(() {
                      _isButtonActive = _firstNameController.text.isNotEmpty &&
                          _lastNameController.text.isNotEmpty &&
                          _emailController.text.isNotEmpty &&
                          _passwordController.text.isNotEmpty;
                    });
                  },
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration:
                            const InputDecoration(labelText: 'First Name'),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your first name'
                            : null,
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration:
                            const InputDecoration(labelText: 'Last Name'),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter your last name'
                            : null,
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration:
                            const InputDecoration(labelText: 'Email Address'),
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
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) => value!.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Use Biometric Authentication"),
                          Switch(
                            value: _useBiometric,
                            onChanged: (value) {
                              setState(() {
                                _useBiometric = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _isButtonActive ? _registerUser : null,
                        child: const Text("Create Account"),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text("Privacy Policy"),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text("Terms and Conditions"),
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
