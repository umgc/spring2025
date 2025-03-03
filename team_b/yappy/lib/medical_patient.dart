import 'package:flutter/material.dart';
import 'package:yappy/speech_state.dart';
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
//Creates a page for the Medical Patient industry
//The page will contain the industry menu and the transcription box
class MedicalPatientPage extends StatelessWidget {
  MedicalPatientPage({super.key});
  final speechState = SpeechState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
      body: ListenableBuilder(
        listenable: speechState,
        builder: (context, child) {
          return Column(
            children: [
              IndustryMenu(
                title: "Medical Patient",
                icon: Icons.local_pharmacy,
                speechState: speechState,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TranscriptionBox(
                    controller: speechState.controller,
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}