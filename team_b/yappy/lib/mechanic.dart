import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  runApp(Mechanical_AidApp());
}

class Mechanical_AidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Mechanical_AidPage(),
    );
  }
}

class Mechanical_AidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: ToolBar(),
      ),
      drawer: HamburgerDrawer(),
      body: Column(
        children: [
          IndustryMenu(title: "Vehicle Maintenance", icon: Icons.directions_car),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranscriptionBox(),
            ),
          ),
        ],
      ),
    );
  }
}
