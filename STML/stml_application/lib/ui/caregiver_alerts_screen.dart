// caregiver_alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class CaregiverAlertsScreen extends StatefulWidget {
  const CaregiverAlertsScreen({Key? key}) : super(key: key);

  @override
  State<CaregiverAlertsScreen> createState() => _CaregiverAlertsScreenState();
}

class _CaregiverAlertsScreenState extends State<CaregiverAlertsScreen> {
  bool _isLoading = false;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    // Log screen view for analytics
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'caregiver_alerts_screen',
    );
  }

  Future<void> _respondToAlert(String docId, String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update status in Firestore
      await FirebaseFirestore.instance
          .collection('helpRequests')
          .doc(docId)
          .update({
        'status': 'responded',
        'responseTime': FieldValue.serverTimestamp(),
      });

      // Log the response for analytics
      await FirebaseAnalytics.instance.logEvent(
        name: 'emergency_alert_responded',
        parameters: {
          'request_id': docId,
          'user_id': userId,
        },
      );

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response confirmed. The user has been notified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Requests'),
        actions: [
          PopupMenuButton<String?>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value == 'all' ? null : value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Requests'),
              ),
              const PopupMenuItem(
                value: 'sent',
                child: Text('Pending Requests'),
              ),
              const PopupMenuItem(
                value: 'responded',
                child: Text('Responded Requests'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _filterStatus == null
                  ? FirebaseFirestore.instance
                      .collection('helpRequests')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('helpRequests')
                      .where('status', isEqualTo: _filterStatus)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == null
                              ? 'No help requests found'
                              : 'No $_filterStatus requests found',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    var userId = data['userId'] as String? ?? 'unknown';
                    var timestamp = data['timestamp'] as Timestamp?;
                    var location = data['location'] as Map<String, dynamic>?;
                    var status = data['status'] as String? ?? 'unknown';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'sent'
                                    ? Colors.red
                                    : Colors.green,
                                child: Icon(
                                  status == 'sent'
                                      ? Icons.warning
                                      : Icons.check,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                'Help requested by ${data['userName'] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                timestamp != null
                                    ? DateFormat.yMMMd()
                                        .add_jm()
                                        .format(timestamp.toDate())
                                    : 'Unknown time',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: status == 'sent'
                                  ? ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Respond'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          _respondToAlert(doc.id, userId),
                                    )
                                  : Chip(
                                      label: const Text('Responded'),
                                      backgroundColor: Colors.green[100],
                                      labelStyle:
                                          TextStyle(color: Colors.green[800]),
                                    ),
                            ),
                            if (location != null && location['address'] != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(location['address']),
                                  ],
                                ),
                              ),
                            ButtonBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                if (location != null &&
                                    (location['latitude'] != null &&
                                        location['longitude'] != null))
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.map),
                                    label: const Text('Open Map'),
                                    onPressed: () {
                                      MapsLauncher.launchCoordinates(
                                        location['latitude'],
                                        location['longitude'],
                                        'Help request location',
                                      );
                                    },
                                  ),
                                if (location != null &&
                                    location['address'] != null)
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.navigation),
                                    label: const Text('Directions'),
                                    onPressed: () {
                                      MapsLauncher.launchQuery(
                                          location['address']);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
