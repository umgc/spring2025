import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yappy/home_page.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/contact_page.dart';
import 'package:yappy/help.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/mechanic.dart';
import 'package:yappy/settings_page.dart';
import 'package:yappy/theme_provider.dart';

// Defines a reusable Hamburger Menu Widget (AppBar + Drawer)
class ToolBar extends StatelessWidget {
  final bool showHamburger;

  const ToolBar({super.key, this.showHamburger = true});
  
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      // Background color based on the theme
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      leading: showHamburger 
        ? Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ) : SizedBox(width: screenHeight * 0.08),
      toolbarHeight: screenHeight * 0.11,
      title: Center(
        child: CircleAvatar(
          backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
          radius: screenWidth * 0.2,
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: screenWidth * 0.22,
            height: screenWidth * 0.22,
          ),
        ),
      ),
      actions: [
        // Information button with dynamic color
        IconButton(
          icon: Icon(Icons.info, color: themeProvider.isDarkMode ? Colors.white : Colors.green),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Information', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
                  content: Text(
                    'Yappy Terms & Conditions\n\nBy using Yappy, you agree to use the app responsibly and comply with all applicable laws. Respect user privacy and refrain from harmful or abusive behavior.\n\nUnderstand that Yappy is not liable for any misuse or legal consequences arising from its use. We may update these terms as needed.\n\nContinued use of Yappy means acceptance of any changes.',
                    style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('OK', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black)),
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

// Creates the hamburger menu
class HamburgerDrawer extends StatelessWidget {
  const HamburgerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    double screenWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Drawer(
        width: screenWidth * .45,
        // Background color based on theme
        backgroundColor: themeProvider.isDarkMode ? Color.fromARGB(255, 79, 79, 83) : Colors.green,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerItem('Home', context, HomePage(), themeProvider),
            _buildDrawerItem('Restaurant', context, RestaurantPage(), themeProvider),
            _buildDrawerItem('Vehicle Maintenance', context, MechanicalAidPage(), themeProvider),
            _buildDrawerItem('Medical Doctor', context, MedicalDoctorPage(), themeProvider),
            _buildDrawerItem('Medical Patient', context, MedicalPatientPage(), themeProvider),
            _buildDrawerItem('Help', context, HelpPage(), themeProvider),
            _buildDrawerItem('Contact', context, ContactPage(), themeProvider),
            _buildDrawerItem('Settings', context, SettingsPage(), themeProvider),
          ],
        ),
      ),
    );
  }

  // Creates the individual drawer items for the hamburger menu
  Widget _buildDrawerItem(String title, BuildContext context, Widget page, ThemeProvider themeProvider) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: themeProvider.isDarkMode ? Colors.white : Colors.black, // Text color based on theme
      tileColor: themeProvider.isDarkMode ? Color.fromARGB(255, 54, 54, 54) : Colors.green.shade200,
      title: Text(
        title,
        style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black), // Text color based on theme
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
}
