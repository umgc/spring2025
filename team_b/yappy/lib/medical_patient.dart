import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';


class MedicalPatientApp extends StatelessWidget {
  const MedicalPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MedicalPatientPage(),
    );
  }
}

class MedicalPatientPage extends StatelessWidget {
  const MedicalPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
      body: Column(
        children: [
        IndustryMenu(title: "Medical Patient", icon: Icons.local_pharmacy),
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