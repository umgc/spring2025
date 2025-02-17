import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';

class Medical_PatientApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Medical_PatientPage(),
    );
  }
}

class Medical_PatientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
    );
  }
}