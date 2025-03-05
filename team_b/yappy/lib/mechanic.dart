import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/speech_state.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: ToolBar(),
      ),
      drawer: HamburgerDrawer(),
      body: ListenableBuilder(
        listenable: speechState,
        builder: (context, child) {
          return Column(
            children: [
              IndustryMenu(
                title: "Vehicle Maintenance",
                icon: Icons.directions_car,
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
