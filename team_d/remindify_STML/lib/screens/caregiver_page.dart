import 'package:flutter/material.dart';

class CaregiverPage extends StatelessWidget {
  const CaregiverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caregiver Mode')),
      body: Center(
        child: Text('Welcome, Caregiver!'),
      ),
    );
  }
}
