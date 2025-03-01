import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/transcription_box.dart';

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
  const RestaurantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
      body: Column(
        children: [
        IndustryMenu(title: "Restaurant", icon: Icons.restaurant_menu),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TranscriptionBox(),
            ),
          ),
        ],
      ),
    );
  }
}