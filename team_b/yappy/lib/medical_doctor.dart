import 'package:flutter/material.dart';
import 'package:yappy/industry_menu.dart';
import 'package:yappy/tool_bar.dart';


class MedicalDoctorApp extends StatelessWidget {
  const MedicalDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MedicalDoctorPage(),
    );
  }
}

class MedicalDoctorPage extends StatelessWidget {
  const MedicalDoctorPage({super.key});

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
        IndustryMenu(title: "Medical Doctor", icon: Icons.medical_services),
    );
  }
}