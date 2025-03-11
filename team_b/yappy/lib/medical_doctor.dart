import 'package:flutter/material.dart';
import 'audiowave_widget.dart';
import 'industry_menu.dart';
import 'tool_bar.dart';
import 'transcription_box.dart';
import 'services/speech_state.dart';
import 'services/model_manager.dart';
import 'search_bar_widget.dart';


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
                  child: SearchBarWidget(industry: "Medical Doctor"),
                ),
                IndustryMenu(
                  title: "Medical Doctor",
                  icon: Icons.medical_services,
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