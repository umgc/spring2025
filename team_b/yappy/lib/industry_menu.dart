import 'package:flutter/material.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'dart:io';
import 'dart:convert'; // Import dart:convert for utf8.encode
import 'package:yappy/services/file_handler.dart'; // Import file_handler

class IndustryMenu extends StatelessWidget {
  final String title;
  final IconData icon;

  const IndustryMenu({required this.title, required this.icon, super.key});

  Widget generateTranscript(
      BuildContext context, String title, String content) {
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
              onPressed: () async {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath = '${directory.path}/$title.txt';
                  final file = File(filePath);
                  await file.writeAsBytes(
                      utf8.encode(content)); // Convert content to bytes

                  // Use FileHandler to add the document
                  FileHandler fileHandler = FileHandler();
                  await fileHandler.addDocument(file);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Transcript saved to $filePath')),
                  );
                  print('File saved at: $filePath');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save file: $e')),
                  );
                  print('Failed to save file: $e');
                }
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
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * .03),

          // Creates a row of clickable menu icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Creates the chat button for each menu
              Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),
                  onPressed: () {
                    //add Bernhards code here
                  },
                ),
              ),
              SizedBox(width: screenWidth * .06),

              // Creates a refine data button
              //after the transcipt is done it will go to this button to be edited.
              //after the edits post it to the database
              Container(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: Colors.grey),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),
                  onPressed: () {
                    // Add your refine data functionality here
                  },
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
                  onPressed: () async {
                    List<Map<String, dynamic>> transcripts =
                        await _fetchTranscripts();
                    showModalBottomSheet(
                      context: context,
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
                                      Map<String, dynamic> transcript =
                                          transcripts[index];
                                      return ListTile(
                                        title: Text(
                                          'Transcript ${transcript['transcript_id']}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          if (title == 'Restaurant') {
                                            // Show Kanban style list for restaurant
                                            showModalBottomSheet(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return KanbanBoard(tasks: [
                                                  'Cheeseburger no lettuce',
                                                  'Rootbeer',
                                                  'Water with lemon and a large cheese pizza'
                                                ]);
                                              },
                                            );
                                          } else {
                                            // Show regular transcript for other industries
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return generateTranscript(
                                                  context,
                                                  'Transcript',
                                                  transcript[
                                                          'transcript_text_data'] ??
                                                      'No content available',
                                                );
                                              },
                                            );
                                          }
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
                    );
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
                  onPressed: () async {
                    // Store the context before async operation
                    List<Map<String, dynamic>> transcripts =
                        await _fetchTranscripts();
                    showModalBottomSheet(
                      context: context,
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
                                      Map<String, dynamic> transcript =
                                          transcripts[index];
                                      return ListTile(
                                        title: Text(
                                          'Transcript ${transcript['transcript_id']}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return generateTranscript(
                                                context,
                                                'Transcript',
                                                transcript[
                                                        'transcript_text_data'] ??
                                                    'No content available',
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
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KanbanBoard extends StatefulWidget {
  final List<String> tasks;

  const KanbanBoard({super.key, required this.tasks});

  @override
  KanbanBoardState createState() => KanbanBoardState();
}

class KanbanBoardState extends State<KanbanBoard> {
  late List<String> tasks;

  @override
  void initState() {
    super.initState();
    tasks = widget.tasks;
  }

  //creates the kanban board sytle widget for the restaurant
  //need to allow the user to edit the order by holding the card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Restaurant Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(tasks[index]),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_upward),
                            onPressed: index > 0
                                ? () {
                                    setState(() {
                                      final temp = tasks[index];
                                      tasks[index] = tasks[index - 1];
                                      tasks[index - 1] = temp;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_downward),
                            onPressed: index < tasks.length - 1
                                ? () {
                                    setState(() {
                                      final temp = tasks[index];
                                      tasks[index] = tasks[index + 1];
                                      tasks[index + 1] = temp;
                                    });
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              TextEditingController controller =
                                  TextEditingController(text: tasks[index]);
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Edit Task'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                          hintText: 'Enter new task'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            tasks[index] = controller.text;
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Save'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add a close button at the bottom
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),

            // Add your save to database functionality here
          ],
        ),
      ),
    );
  }
}
