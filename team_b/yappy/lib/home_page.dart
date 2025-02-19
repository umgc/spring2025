import 'package:flutter/material.dart';
import 'package:yappy/contact_page.dart';
import 'package:yappy/help.dart';
import 'package:yappy/mechanic.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/tool_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: ToolBar(), // Using the ToolBar widget
      ),
      drawer: HamburgerDrawer(), // Add the HamburgerDrawer for navigation
      body: Column(
        children: [
          _buildButton('Restaurant', context, RestaurantPage()),
          _buildButton('Mechanical Aid', context, Mechanical_AidPage()),
          _buildButton('Medical Doctor', context, Medical_DoctorPage()),
          _buildButton('Medical Patient', context, Medical_PatientPage()),
          _buildButton('Help', context, HelpPage()),
          _buildButton('Contact', context, ContactPage()),
        ],
      ),
    );
  }

  // Function for button navigation
  Widget _buildButton(String text, BuildContext context, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: Colors.white,
      tileColor: const Color.fromARGB(255, 54, 54, 54),
      title: Text(title),
      onTap: () {
        // TODO Navigate to the corresponding screen
      },
    );
  }
}

