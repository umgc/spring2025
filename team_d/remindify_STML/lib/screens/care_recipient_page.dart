import 'package:flutter/material.dart';

class CareRecipientPage extends StatelessWidget {
  const CareRecipientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Care Recipient Mode')),
      body: Center(
        child: Text('Welcome, Care Recipient!'),
      ),
    );
  }
}
