import 'package:flutter/material.dart';
import 'audiowave_widget.dart';
import 'industry_menu.dart';
import 'tool_bar.dart';
import 'transcription_box.dart';
import 'services/speech_state.dart';
import 'services/model_manager.dart';
import 'search_bar_widget.dart';

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
//Creates a page for the Mechanical Aid industry
//The page will contain the industry menu and the transcription box
class MechanicalAidPage extends StatelessWidget {
  MechanicalAidPage({super.key});
  final speechState = SpeechState();
  final modelManager = ModelManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: ToolBar(),
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
                child: SearchBarWidget(industry: "Vehicle Maintenance"),
              ),

              IndustryMenu(
                title: "Vehicle Maintenance",
                icon: Icons.directions_car,
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
