import 'package:flutter/material.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/contact_page.dart';
import 'package:yappy/help.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/mechanic.dart';

// Defines a reusable Hamburger Menu Widget (AppBar + Drawer)
class ToolBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      return AppBar(
          // Creates the hamburger icon for the menu
          backgroundColor: Colors.black,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          toolbarHeight: 140,
          // Contains the Yappy! icon
          title: Center(
            child: CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              radius: 140,
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 140,
                height: 140,
              ),
            ),
          ),
          actions: [
            // Contains the information button
            IconButton(
              icon: const Icon(Icons.info, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // Creates a pop up when the button is pressed
                    return AlertDialog(
                      title: const Text('Information'),
                      content: const Text('Your Terms & Conditions info goes here.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
  }
}
  // creates the hamburger menu
class HamburgerDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 175,
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerItem('Home', context, HomePage()),
          _buildDrawerItem('Restaurant', context, RestaurantPage()),
          _buildDrawerItem('Mechanical Aid', context, Mechanical_AidPage()),
          _buildDrawerItem('Medical Doctor', context, Medical_DoctorPage()),
          _buildDrawerItem('Medical Patient', context, Medical_PatientPage()),
          _buildDrawerItem('Help', context, HelpPage()),
          _buildDrawerItem('Contact', context, ContactPage()),
        ],
      ),
    );
  }

  // Creates the individual drawer items for the hamburger menu
  Widget _buildDrawerItem(String title, BuildContext context, Widget page) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: Colors.white,
      tileColor: const Color.fromARGB(255, 54, 54, 54),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          // Navigates to the page once the button is clicked
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}