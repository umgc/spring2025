import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:yappy/speech_state.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:share_plus/share_plus.dart';

class IndustryMenu extends StatelessWidget {
  final String title;
  final IconData icon;
  final SpeechState speechState;

  const IndustryMenu({required this.title, required this.icon, required this.speechState, super.key}); 
    Widget generateTranscript(BuildContext context, String title, String content) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          //add export capes
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                // Add your share functionality here
                Share.share(
                  content,
                  subject: title,
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                // Add your download functionality here
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Add your delete functionality here
              },
              ),
            ],
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    }

  Future<List<Map<String, dynamic>>> _fetchTranscripts() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    
    return await dbHelper.getAllTranscripts();
  }

  @override
  Widget build(BuildContext context) {
    // Gets the width and height of the current screen
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),

      // Creates a column for the items within the menu
      child: Column(
        children: [
          Center(
            // Creates the text box above the icons
            child: Container(
                width: screenWidth * .75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color.fromARGB(255, 67, 67, 67),
                ),
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white
                    ),
                  ),
                )),
          ),
          SizedBox(height: screenHeight * .03),

          // Creates a row of clickable menu icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Creates the chat button for each menu
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: speechState.recordState == RecordState.stop ? Colors.grey : Colors.red
                ),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    speechState.recordState == RecordState.stop ? Icons.mic : Icons.stop,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),
                  onPressed: () => speechState.toggleRecording(),
                ),
              ),
              SizedBox(width: screenWidth * .06),

              // Creates a industry specific icon based on user input
              Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    icon,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),

                  onPressed: () {

                  },
                ),
              ),
              SizedBox(width: screenWidth * .06),

              // Creates a transcript history button
              Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    Icons.file_copy,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),
                  onPressed: () {
                    // Store the context before async operation
                    final BuildContext currentContext = context;

                    // Load transcripts and then show modal
                    _fetchTranscripts().then((transcripts) {
                      if (!currentContext.mounted) return;

                        showModalBottomSheet(
                          context: currentContext,
                          builder: (BuildContext context) {
                          return Container(
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color.fromARGB(255, 67, 67, 67),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: transcripts.length,
                                    itemBuilder: (context, index) {
                                      Map<String, dynamic> transcript = transcripts[index];
                                      return ListTile(
                                        title: Text(
                                          'Transcript ${transcript['transcript_id']}',
                                          style: TextStyle(
                                            color: Colors.white
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return generateTranscript(
                                              context,
                                                'Transcript',
                                                transcript['transcript_text_data'] ?? 'No content available',
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );});
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
