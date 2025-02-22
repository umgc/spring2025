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
  final bool showHamburger;

  ToolBar({this.showHamburger = true});
  
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return AppBar(
        // Creates the hamburger icon for the menu
        backgroundColor: Colors.black,
        leading: showHamburger 
          ? Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ): SizedBox(width: screenHeight * 0.08),
        toolbarHeight: screenHeight * 0.11,
        // Contains the Yappy! icon
        title: Center(
          child: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            radius: screenWidth * 0.2,
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: screenWidth * 0.22,
              height: screenWidth * 0.22,
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
  // creates the hamburger menu
class HamburgerDrawer extends StatelessWidget {
  const HamburgerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Drawer(
        width: screenWidth * .45,
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerItem('Home', context, HomePage()),
            _buildDrawerItem('Restaurant', context, RestaurantPage()),
            _buildDrawerItem('Vehicle Maintenance', context, MechanicalAidPage()),
            _buildDrawerItem('Medical Doctor', context, MedicalDoctorPage()),
            _buildDrawerItem('Medical Patient', context, MedicalPatientPage()),
            _buildDrawerItem('Help', context, HelpPage()),
            _buildDrawerItem('Contact', context, ContactPage()),
          ],
        ),
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