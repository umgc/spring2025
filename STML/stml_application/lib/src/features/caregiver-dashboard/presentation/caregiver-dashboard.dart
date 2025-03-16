// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_service.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_stream_service.dart';
import 'package:memoryminder/ui/dementia_resources.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';



// Main HomeScreen widget which is a stateless widget.
class CaregiverDashboardScreen extends StatefulWidget {
  @override
  _CaregiverDashboardScreen createState() => _CaregiverDashboardScreen();
}

class _CaregiverDashboardScreen extends State<CaregiverDashboardScreen> {
  double iconSize = 65;
  final NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.getRecentNotifications();
  }

  @override
  void dispose() {
    NotificationStreamService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color for the entire screen
        extendBodyBehindAppBar: true,
        extendBody: true,
        // Setting up the app bar at the top of the screen
        appBar: AppBar(
          backgroundColor: Colors.blueAccent, // Set appbar background color
          elevation: 0.0,
          centerTitle: true, // This centers the title
          automaticallyImplyLeading: false,

          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize
                    .min, // This ensures the Row takes the least amount of space
                children: [
                  Image.asset(
                    'assets/icons/app_icon.png', // Replace this with your icon's path
                    fit: BoxFit.contain,
                    height: 32, // Adjust the size as needed
                  ),
                  const SizedBox(width: 10), // Spacing between the icon and title
                  const Text('Caregiver Dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Text(
                _currentDate(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          // Widgets on the right side of the AppBar
          actions: [
            // First page icon to navigate back
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.black87,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),

            // First page icon to navigate back
            IconButton(
              icon: const Icon(
                Icons.first_page,
                color: Colors.black87,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        ///////////////////////////
        // Main content of the screen

        body:
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'), // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),

          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(2.0, 100, 16.0, 2),
                child: Text(
                  'Notifications',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: StreamBuilder(stream: NotificationStreamService().stream,
                  initialData: [],
                  builder: (context, snapshot) {
                    int itemCount = 0;
                    if (snapshot.hasData) {
                      List<dynamic> unReadNotifications = snapshot.data!.where((item) => item['read'] == false).toList();
                      itemCount = unReadNotifications.length;
                    }
                    return Text(
                      'You have $itemCount unread notifications.',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(2.0, 2, 2.0, 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),  // Rounded corners
                  ),
                  child:
                  _buildNotificationList(
                    context: context,
                  ),

                ),
              ),

              const Divider(
                color: Colors.black54, // Optional: change the color
                thickness: 2, // Optional: change the thickness
                height: 10, // Optional: add vertical space around the line
                indent: 20, // Optional: indent the line from the start
                endIndent: 20, // Optional: indent the line from the end
              ),

              // Grid view to display multiple options/buttons
              GridView.count(
                shrinkWrap: true, // Add shrinkWrap
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.30,
                padding: const EdgeInsets.all(6.0),
                children: [
                  // Using the helper function to build each button in the grid
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.person_2,
                        size: iconSize, color: Colors.black87),
                    text: 'Jessica Thompson',
                    screen: ProfileScreen(),
                    keyName: "VirtualAssistantButtonKey",
                  ),
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.person_2,
                        size: iconSize, color: Colors.black87),
                    text: 'Michael Brown',
                    screen: ProfileScreen(),
                    keyName: "GalleryButtonKey",
                  ),

                ],
              ),

              const Divider(
                color: Colors.black, // Optional: change the color
                thickness: 2, // Optional: change the thickness
                height: 10, // Optional: add vertical space around the line
                indent: 20, // Optional: indent the line from the start
                endIndent: 20, // Optional: indent the line from the end
              ),

              // Grid view to display multiple options/buttons

              GridView.count(
                shrinkWrap: true, // Add shrinkWrap
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 1,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1,
                padding: const EdgeInsets.fromLTRB(130.0,2, 130.0, 2),
                children: [
                  _buildElevatedButton(
                    context: context,
                    icon: Icon(Icons.bookmark_outline,
                        size: iconSize, color: Colors.black87),
                    text: 'Dementia Resources',
                    screen: DementiaResourcesScreen(),
                    keyName: "DementiaResourcesButtonKey",
                  ),
                ],
              ),
            ],
          ),
        ),


        // Bottom navigation bar with multiple options for quick navigation
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

  String _currentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy'); // You can customize the format here
    return formatter.format(now);
  }

  // Helper function to create each button for the GridView
  Widget _buildElevatedButton({
    required BuildContext context,
    required Icon icon,
    required String text,
    required Widget screen,
    required String keyName,
  }) {
    return ElevatedButton(
      key: Key(keyName),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor:
        const Color(0xFFFFFFFF).withOpacity(0.30), // Button text color
        padding: const EdgeInsets.all(16.0),
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
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
              color: Color(0XFF000000),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList({
    required BuildContext context,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: NotificationStreamService().stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No notifications available'));
        }

        // List of notifications
        List<Map<String, dynamic>> notifications = snapshot.data!;

        return Container(height: 300, child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var notification = notifications[index];

            return ListTile(
              title: Text(notification['title'],
                style: TextStyle(
                  fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
                  fontSize: notification['read'] ? 16 : 18,
                  color: Colors.black,
                ),
              ),

              leading: notification['read']
                  ? Icon(Icons.check_circle_outline_sharp, color: Colors.green)
                  : Icon(Icons.notifications, color: Colors.red),

              onTap: () {
                // Handle notification tap and mark as read
                notificationService.markNotificationAsRead(notification['id']);
              },
            );
          },
        )
        );
      },
    );

  }
}