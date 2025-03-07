import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:yappy/speech_state.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:yappy/services/file_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'services/model_manager.dart';

class IndustryMenu extends StatefulWidget {
  final String title;
  final IconData icon;
  final SpeechState speechState;
  final ModelManager modelManager;

  const IndustryMenu({
    required this.title, 
    required this.icon,
    required this.speechState,
    required this.modelManager,
    super.key
  }); 

  @override
  State<IndustryMenu> createState() => _IndustryMenuState();
}

class _IndustryMenuState extends State<IndustryMenu> {
  bool modelsExist = false;

  @override
  void initState() {
    super.initState();
    _checkModels();
  }

  Future<void> _checkModels() async {
    final exist = await widget.modelManager.modelsExist();
    if (mounted) {
      setState(() {
        modelsExist = exist;
      });
    }
  }

  Widget generateTranscript(BuildContext context, String title, String content, int transcript) {
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
                  // Request storage permission
                  if (await Permission.storage.request().isGranted ||
                      await Permission.manageExternalStorage
                          .request()
                          .isGranted) {
                    // Attempt to find the Downloads directory
                    final directories = await getExternalStorageDirectories(
                        type: StorageDirectory.downloads);
                    final downloadsDirectory = directories?.first;

                    if (downloadsDirectory != null) {
                      final filePath = '${downloadsDirectory.path}/$title.txt';
                      final file = File(filePath);
                      await file.writeAsBytes(utf8.encode(content),
                          flush: true);

                      await MethodChannel('com.yourcompany.yappy/files')
                          .invokeMethod('scanFile', {'filePath': filePath});

                      FileHandler fileHandler = FileHandler();
                      await fileHandler.addDocument(file);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Transcript saved to $filePath')),
                        );
                      }
                      debugPrint('File saved at: $filePath');
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Failed to find Downloads directory')),
                        );
                      }
                    }
                  } else {
                      if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Storage permission denied')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save file: $e')),
                    );
                  }
                  debugPrint('Failed to save file: $e');
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
                  widget.title,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            )
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
                  color: !modelsExist 
                    ? Color.fromRGBO(128, 128, 128, 0.5)
                    : (widget.speechState.recordState == RecordState.stop ? Colors.grey : Colors.red)
                ),
                padding: EdgeInsets.all(5),
                child: Tooltip(
                  message: !modelsExist 
                    ? "Download required models to enable recording"
                    : (widget.speechState.recordState == RecordState.stop ? "Start recording" : "Stop recording"),
                  child: IconButton(
                    icon: Icon(
                      widget.speechState.recordState == RecordState.stop ? Icons.mic : Icons.stop,
                      color: !modelsExist ? Color.fromRGBO(255, 255, 255, 0.5) : Colors.white,
                      size: screenHeight * .05,
                    ),
                    onPressed: !modelsExist ? null : () async {
                      await widget.speechState.toggleRecording();
                      // When speechState.stop happens it needs to store the text in the database
                      // The new text file needs to get the USERID, create a new Transcript ID,
                      // The user will be asked to edit the text to ensure accuracy. After hitting save, the text will be saved to the database in the transcript table using the same transcript ID
                      if (widget.speechState.recordState == RecordState.stop) {
                        // Fetch the recorded text
                        String recordedText = await widget.speechState.getRecordedText();

                        // Get the user ID (assuming you have a method to get the current user ID)
                          int userId = 0001;

                        // Create a new transcript ID 
                            int transcriptId = DateTime.now().millisecondsSinceEpoch;

                        // Show a dialog to edit the text
                        TextEditingController controller = TextEditingController(text: recordedText);
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Edit Transcript'),
                              content: TextField(
                                controller: controller,
                                decoration: InputDecoration(hintText: 'Edit the transcript text'),
                                maxLines: null,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    // Save the edited text to the database
                                    await DatabaseHelper().saveTranscript(
                                      userId: userId,
                                      transcriptId: transcriptId,
                                      text: controller.text,
                                    );
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
                      }
                    }
                  ),
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
                    widget.icon,
                    color: Colors.white,
                    size: screenHeight * .05,
                  ),
                  onPressed: () {
                    _showTranscriptsBottomSheet(context);
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
                    _showTranscriptsHistoryBottomSheet(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Extract the functionality to show transcripts into a separate method
  void _showTranscriptsBottomSheet(BuildContext context) async {
    // Fetch transcripts first
    List<Map<String, dynamic>> transcripts = await _fetchTranscripts();

    // Check if the context is still valid
    if (!context.mounted) return;

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
                      Map<String, dynamic> transcript = transcripts[index];
                      return ListTile(
                        title: Text(
                          'Transcript ${transcript['transcript_id']}',
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.title == 'Restaurant') {
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
                                  transcript['transcript_text_data'] ?? 'No content available',
                                  transcript['transcript_id'],
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
  }    

  // Extract the functionality to show transcript history into a separate method
  void _showTranscriptsHistoryBottomSheet(BuildContext context) async {
    // Fetch transcripts first
    List<Map<String, dynamic>> transcripts = await _fetchTranscripts();

    // Check if the context is still valid
    if (!context.mounted) return;

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
                      Map<String, dynamic> transcript = transcripts[index];
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
                                transcript['transcript_text_data'] ?? 'No content available',
                                transcript['transcript_id'],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // Add an upload bar at the bottom
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Add your upload functionality here
                    },
                    icon: Icon(Icons.upload),
                    label: Text('Upload Transcript'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 26, 26, 27),
                      foregroundColor: const Color.fromARGB(255, 229, 217, 217),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
