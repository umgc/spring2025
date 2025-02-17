import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';


class Mechanical_AidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Mechanical_AidPage(),
    );
  }
}

class Mechanical_AidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
    );
  }
}