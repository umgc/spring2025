// ignore_for_file: avoid_print, prefer_const_constructors
// Imported libraries and packages

import 'dart:async';

import 'package:memoryminder/src/features/caregiver-dashboard/model/CareRecipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/add_care_recipient.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/app_bar.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/presentation/care_recipient_profile.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/manage_care_recipient_service.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_service.dart';
import 'package:memoryminder/src/features/caregiver-dashboard/service/notification_stream_service.dart';
import 'package:memoryminder/ui/profile_screen.dart';
import 'package:memoryminder/src/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Main HomeScreen widget which is a stateless widget.
class CaregiverDashboardScreen extends StatefulWidget {
  @override
  _CaregiverDashboardScreen createState() => _CaregiverDashboardScreen();
}

class _CaregiverDashboardScreen extends State<CaregiverDashboardScreen> {
  double iconSize = 65;
  final NotificationService notificationService = NotificationService();
  late Future<List<Map<String, dynamic>>> _careRecipientData;

  @override
  void initState() {
    super.initState();
    notificationService.getRecentNotifications();
    _careRecipientData = ManageCareRecipientService().getAllCareRecipients();
  }

  Future<void> _callEmergencyNumber() async {
    const phoneNumber =
        'tel:911'; // Remplacez par le numéro d'urgence approprié
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  void dispose() {
    NotificationStreamService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        // Setting up the app bar at the top of the screen
        appBar: const CustomAppBar(
          title: 'Caregiver Dashboard',
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(2.0, 2, 16.0, 2),
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
                child: StreamBuilder(
                    stream: NotificationStreamService().stream,
                    initialData: [],
                    builder: (context, snapshot) {
                      int itemCount = 0;
                      if (snapshot.hasData) {
                        List<dynamic> unReadNotifications = snapshot.data!
                            .where((item) => item['read'] == false)
                            .toList();
                        itemCount = unReadNotifications.length;
                        return Text(
                          'You have $itemCount unread notifications.',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else
                        return Text('');
                    }),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(2.0, 2, 2.0, 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: _buildNotificationList(
                    context: context,
                  ),
                ),
              ),
              const Divider(
                color: Colors.black54,
                thickness: 2,
                height: 10,
                indent: 20,
                endIndent: 20,
              ),
              const Divider(
                color: Colors.black54,
                thickness: 2,
                height: 10,
                indent: 20,
                endIndent: 20,
              ),
              ElevatedButton(
                onPressed: _callEmergencyNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.red, // Couleur rouge pour indiquer l'urgence
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Emergency Call',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const Divider(
                color: Colors.black54,
                thickness: 2,
                height: 10,
                indent: 20,
                endIndent: 20,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(2.0, 2, 2.0, 2),
                child: Column(
                  children: [
                    Text(
                      'Care Recipients   ',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddCareRecipientForm()),
                        );
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.black,
                      ),
                      label: Text("Add New Care Recipient"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.fromLTRB(
                            2.0, 2, 16.0, 2), // Apply padding here
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildCareRecipientsGrid(
                  context: context,
                ),
              ),
              const Divider(
                color: Colors.black,
                thickness: 2,
                height: 10,
                indent: 20,
                endIndent: 20,
              ),
            ],
          ),
        ),

        // Bottom navigation bar with multiple options for quick navigation
        bottomNavigationBar: UiUtils.createBottomNavigationBar(context));
  }

  Widget _buildCareRecipientsGrid({
    required BuildContext context,
  }) {
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _careRecipientData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // Adjust as needed
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final String labelText =
                    '${item['firstName'].toString()} ${item['lastName'].toString()}';
                final careRecipient = CareRecipient.fromMap(item);
                return InkWell(
                    // Or InkWell for ripple effect
                    onTap: () {
                      // Handle item click
                      print('Item ${item['firstName'].toString()} clicked');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CareRecipientProfileScreen(
                                careRecipientId: item['itemId'].toString(),
                                careRecipientData: careRecipient.toMap())),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.lightGreen[100],
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.lightGreen.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.person,
                            size: 40.0,
                            color: Colors.green,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            labelText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ));
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
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

        return Container(
            height: 300,
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];

                return ListTile(
                  title: Text(
                    notification['title'],
                    style: TextStyle(
                      fontWeight: notification['read']
                          ? FontWeight.normal
                          : FontWeight.bold,
                      fontSize: notification['read'] ? 16 : 18,
                      color: Colors.black,
                    ),
                  ),
                  leading: notification['read']
                      ? Icon(Icons.check_circle_outline_sharp,
                          color: Colors.green)
                      : Icon(Icons.notifications, color: Colors.red),
                  onTap: () {
                    // Handle notification tap and mark as read
                    notificationService
                        .markNotificationAsRead(notification['id']);
                  },
                );
              },
            ));
      },
    );
  }
}
