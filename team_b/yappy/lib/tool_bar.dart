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
            IconButton(
              icon: const Icon(Icons.info, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Information'),
                      content: const Text('Yappy Terms & Conditions\n\n''By using Yappy,'
                                  'you agree to Use the app responsibly and comply '
                                  'with all applicable laws. Respect user privacy '
                                  'and refrain from harmful or abusive behavior.\n\n'
                                  'Understand that Yappy is not liable for '
                                  'any misuse or legal consequences arising from its use. '
                                  'We may update these terms as needed.\n\n'
                                  'Continued use of Yappy means acceptance of any changes..'),
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
  // Separate Drawer Widget
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

  Widget _buildDrawerItem(String title, BuildContext context, Widget page) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: Colors.white,
      tileColor: const Color.fromARGB(255, 54, 54, 54),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}