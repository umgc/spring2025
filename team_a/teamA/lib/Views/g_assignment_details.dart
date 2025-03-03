import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart'; // Import url_launcher

class AssignmentDetailsPage extends StatelessWidget {
  final dynamic assignment;

  AssignmentDetailsPage({required this.assignment});

  // Function to format the date
  String? formatDate(dynamic date) {
    if (date == null) return 'Not specified';
    try {
      DateTime parsedDate = DateTime(date['year'], date['month'], date['day']);
      return DateFormat('MMM d, yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Function to launch URL
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CustomAppBar(
      //   title: assignment['title'] ?? 'Assignment Details',
      //   userprofileurl: MoodleApiSingleton().profileImage ?? '',
      // ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap with SingleChildScrollView
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch columns to full width
            children: [
              _buildDetailCard('Title', assignment['title'] ?? 'No title'),
              SizedBox(height: 10),
              _buildDetailCard(
                  'Description', assignment['description'] ?? 'No description'),
              SizedBox(height: 10),
              _buildDetailCard('State', assignment['state'] ?? 'N/A'),
              SizedBox(height: 10),
              _buildLinkCard(
                  'Alternate Link', assignment['alternateLink'], context),
              SizedBox(height: 10),
              _buildDetailCard(
                  'Creation Time', assignment['creationTime'] ?? 'N/A'),
              SizedBox(height: 10),
              _buildDetailCard(
                  'Update Time', assignment['updateTime'] ?? 'N/A'),
              SizedBox(height: 10),
              _buildDetailCard('Due Date', formatDate(assignment['dueDate'])),
              SizedBox(height: 10),
              _buildDetailCard('Max Points', assignment['maxPoints'] ?? 'N/A'),
              SizedBox(height: 10),
              _buildDetailCard('Work Type', assignment['workType'] ?? 'N/A'),
              SizedBox(height: 10),

              // Conditionally display assignment details if present
              if (assignment['assignment'] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text('Assignment Details:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                // Access and display details specific to the 'assignment' object
              ],

              // Conditionally display multiple choice question details if present
              if (assignment['multipleChoiceQuestion'] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text('Multiple Choice Question Details:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                // Access and display details specific to the 'multipleChoiceQuestion' object
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each detail card with bold label
  Widget _buildDetailCard(String label, String? value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
            color: Colors.grey[300]!, width: 1.0), // Add a subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12.0, horizontal: 16.0), // Add padding
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: Colors.black),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: value ?? 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each detail card with clickable link
  Widget _buildLinkCard(String label, String? url, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
            color: Colors.grey[300]!, width: 1.0), // Add a subtle border
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12.0, horizontal: 16.0), // Add padding
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: Colors.black),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (url != null && url.isNotEmpty)
                TextSpan(
                  text: url,
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      _launchURL(url);
                    },
                )
              else
                TextSpan(text: 'N/A'),
            ],
          ),
        ),
      ),
    );
  }
}
