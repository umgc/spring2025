import 'package:flutter/material.dart';
import 'audiowave_widget.dart';
import 'tool_bar.dart';
import 'industry_menu.dart';
import 'transcription_box.dart';
import 'services/speech_state.dart';
import 'services/model_manager.dart';
import 'package:yappy/search_bar_widget.dart';

class RestaurantPage extends StatelessWidget {
  RestaurantPage({super.key});
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
                // Padding the search bar and using a smaller height
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SearchBarWidget(industry: "Restaurant"),
                ),
                // The rest of the widgets below the search bar
                IndustryMenu(
                  title: "Restaurant", 
                  icon: Icons.restaurant_menu,
                  speechState: speechState,
                  modelManager: modelManager,
                ),    

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      AudiowaveWidget(speechState: speechState),
                      TranscriptionBox(
                        controller: speechState.controller,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

