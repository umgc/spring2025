import 'package:flutter/material.dart';
import 'package:yappy/audiowave_widget.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/services/speech_state.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'services/model_manager.dart';


class MedicalPatientApp extends StatelessWidget {
  const MedicalPatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TutorialPage(),
    );
  }
}
//Creates a page for the Medical Patient industry
//The page will contain the industry menu and the transcription box
class TutorialPage extends StatelessWidget {
  TutorialPage({super.key});
  final speechState = SpeechState();
  final modelManager = ModelManager();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialPopup(context);
    });

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
                title: "Tutorial",
                icon: Icons.local_pharmacy,
                speechState: speechState,
                modelManager: modelManager,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(children: [
                    AudiowaveWidget(speechState: speechState),
                    TranscriptionBox(
                      controller: speechState.controller,
                    ),
                  ],)

                ),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showTutorialPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("The button of the left is the Record button that allows you to record conversations and get a transcript in return."),
          ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showSecondPopup(context);
          },
          child: Text("Next"),
          ),
        ],
        ),
      );
      },
    );
    }

    void _showSecondPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("The middle button will show you the days transcripts with broken down into details."),
          ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showThirdPopup(context);
          },
          child: Text("Next"),
          ),
        ],
        ),
      );
      },
    );
    }

    void _showThirdPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
      return AlertDialog(
      content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("The button on the right will show you all transcripts and allow you to search, share, upload, download, and delete."),
        ElevatedButton(
        onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage())
        );
        },
        child: Text("Finish"),
        ),
      ],
      ),
      );
      },
    );
  }
}



  