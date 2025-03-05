import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/speech_state.dart';
import 'package:yappy/speech_state.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';
import 'services/model_manager.dart';

class MedicalDoctorApp extends StatelessWidget {
  const MedicalDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MedicalDoctorPage(),
    );
  }
}
//Creates a page for the Medical Doctor industry
//The page will contain the industry menu and the transcription box
class MedicalDoctorPage extends StatelessWidget {
  MedicalDoctorPage({super.key});
  final speechState = SpeechState();
  final modelManager = ModelManager();

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
                title: "Medical Doctor",
                icon: Icons.medical_services,
                speechState: speechState,
                modelManager: modelManager,
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