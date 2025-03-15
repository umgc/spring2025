import 'package:flutter/material.dart';
import 'audiowave_widget.dart';
import 'tool_bar.dart';
import 'industry_menu.dart';
import 'transcription_box.dart';
import 'services/speech_state.dart';
import 'services/model_manager.dart';
import 'search_bar_widget.dart';


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
  final modelManager = ModelManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
      body: ListenableBuilder(
        listenable: speechState,
        builder: (context, child) {
          return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SearchBarWidget(industry: "Medical Patient"),
                  ),
                  IndustryMenu(
                    title: "Medical Patient",
                    icon: Icons.local_pharmacy,
                    speechState: speechState,
                    modelManager: modelManager,
                  ),
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(children: [
                        AudiowaveWidget(speechState: speechState),
                        TranscriptionBox(
                          controller: speechState.controller,
                        ),
                      ],)
                    ),
                ],
              )
          );

        }
      ),
    );
  }
}