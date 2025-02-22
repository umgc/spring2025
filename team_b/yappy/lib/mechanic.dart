import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';

void main() {
  runApp(MechanicalAidApp());
}

class MechanicalAidApp extends StatelessWidget {
  const MechanicalAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MechanicalAidPage(),
    );
  }
}

class MechanicalAidPage extends StatelessWidget {
  const MechanicalAidPage({super.key});

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
