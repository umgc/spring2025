import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/tool_bar.dart';


class MechanicalAidApp extends StatelessWidget {
  const MechanicalAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MechanicalAidPage(),
    );
  }
}

class MechanicalAidPage extends StatelessWidget {
  const MechanicalAidPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),

      body: 
        IndustryMenu(title: "Mechanical Aid", icon: Icons.directions_car),
    );
  }
}