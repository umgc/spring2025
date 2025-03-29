// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/add_care_recipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/caregiver-dashboard.dart';
import 'package:memoryminder/src/features/caregiver_task_management/presentation/caregiver_task_screen.dart';
import 'package:memoryminder/src/features/dementia-resources/presentation/dementia_resources.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';


// Main HomeScreen widget which is a stateless widget.
class CareRecipientProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? careRecipientData;
  final String? careRecipientId;
  const CareRecipientProfileScreen({this.careRecipientId, this.careRecipientData});

  @override
  CareRecipientProfileScreenState createState() => CareRecipientProfileScreenState();
}

class CareRecipientProfileScreenState extends State<CareRecipientProfileScreen> {
  bool hasBeenInitialized = false;
  double iconSize = 65;

  @override
  void initState() {
    super.initState();
  }

  String getCareRecipientLocation() {
    List<String> nonNullStrings = [];

    if(widget.careRecipientData!['city'] != null &&  widget.careRecipientData!['city'].isNotEmpty) {
      nonNullStrings.add(widget.careRecipientData!['city']);
    }
    if(widget.careRecipientData!['county'] != null &&  widget.careRecipientData!['county'].isNotEmpty) {
      nonNullStrings.add(widget.careRecipientData!['county']);
    }
    if(widget.careRecipientData!['state'] != null &&  widget.careRecipientData!['state'].isNotEmpty) {
      nonNullStrings.add(widget.careRecipientData!['state']);
    }
    return nonNullStrings.join(', ');
  }
  @override
  Widget build(BuildContext context) {
    final String careRecipientName = '${widget.careRecipientData!['firstName']} ${widget.careRecipientData!['lastName']}';
    final String careRecipientLocation = getCareRecipientLocation();
    return Scaffold(
        extendBody: true,
        // Setting up the app bar at the top of the screen
        appBar: const CustomAppBar(
          title: 'Recipient Profile',
        ),
        // Main content of the screen
        body: Container(

          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 140, 16.0, 25),
                child: Text(
                  careRecipientName,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Grid view to display multiple options/buttons

              Expanded(
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.30,
                  padding: const EdgeInsets.all(26.0),
                  children: [
                    // Using the helper function to build each button in the grid
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.health_and_safety_rounded,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Health Metrics',
                      routeName: '/healthMetrics',
                      keyName: "HealthMetricsButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.task,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Tasks',
                      screen: CaregiverTaskScreen(),
                      keyName: "TaskButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.maps_home_work,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Location',
                      screen: LoginScreen(),
                      keyName: "LocationButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.person,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Update Profile',
                      screen: AddCareRecipientForm(itemId: widget.careRecipientId, initialData: widget.careRecipientData),
                      keyName: "UpdateProfileButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.bookmark_outline,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Dementia Resources',
                      screen: DementiaResourcesScreen(loc: careRecipientLocation),
                      keyName: "DementiaResourcesButtonKey",
                    ),
                    _buildElevatedButton(
                      context: context,
                      icon: Icon(Icons.language,
                          size: iconSize, color: Color.fromARGB(255, 2, 63, 129)),
                      text: 'Language Preferences',
                      screen: LoginScreen(),
                      keyName: "LanguagePreferencesButtonKey",
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom navigation bar with multiple options for quick navigation
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

  // Helper function to create each button for the GridView
  Widget _buildElevatedButton({
    required BuildContext context,
    required Icon icon,
    required String text,
    Widget? screen,
    String? routeName,
    required String keyName,
  }) {
    return ElevatedButton(
      key: Key(keyName),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.lightBlue[100],

        padding: const EdgeInsets.all(16.0),
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),

        ),
      ),
      onPressed: () {
        if (routeName != null) {
          Navigator.pushNamed(context, routeName); // Use named route if provided
        } else if (screen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen), // Default behavior
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 10.0),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}