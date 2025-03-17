// create flutter/dart screen which will display scam detail
//display scam detail
// return home page button at the bottom of the screen


import 'package:flutter/material.dart';
import 'package:memoryminder/src/database/transcript_database.dart';

class ScamDetailScreen extends StatelessWidget {
  final int scamId;
  TranscriptDatabaseHelper _transcriptDatabaseHelper;

  ScamDetailScreen({required this.scamId, TranscriptDatabaseHelper? transcriptDatabaseHelper})
      : _transcriptDatabaseHelper = transcriptDatabaseHelper ?? TranscriptDatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Back', style: TextStyle(color: Colors.black54)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _transcriptDatabaseHelper.getNote(scamId), // Fetch the note based on scamId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading spinner while waiting for the data
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Show an error message if something went wrong
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Data is available, display it
            final note = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scam Note:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(note['note'] ?? 'No note available'),
                  SizedBox(height: 16),
                  Text(
                    'Source:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(note['source'] ?? 'No source available'),
                  SizedBox(height: 16),
                  Text(
                    'Date:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(note['date'] ?? 'No date available'),
                  SizedBox(height: 16),
                  Text(
                    'Creation Time:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(note['create_time'] ?? 'No time available'),
                  Spacer(),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}
