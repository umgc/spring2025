import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';
import 'package:yappy/speech_state.dart';
<<<<<<< HEAD
=======
import 'services/model_manager.dart';
>>>>>>> developer

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
<<<<<<< HEAD
=======
  final modelManager = ModelManager();
>>>>>>> developer

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
<<<<<<< HEAD
=======
                modelManager: modelManager,
>>>>>>> developer
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