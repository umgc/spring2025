import 'package:flutter/material.dart';
import 'audiowave_widget.dart';
import 'tool_bar.dart';
import 'industry_menu.dart';
import 'transcription_box.dart';
import 'services/speech_state.dart';
import 'services/model_manager.dart';

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RestaurantPage(),
    );
  }
}
//Creates a page for the Restaurant industry
//The page will contain the industry menu and the transcription box
class RestaurantPage extends StatelessWidget {
  RestaurantPage({super.key});
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
                title: "Restaurant", 
                icon: Icons.restaurant_menu,
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
}