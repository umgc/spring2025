import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/tutorial_page.dart';


class HelpApp extends StatelessWidget {
  const HelpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HelpPage(),
    );
  }
}
//Creates a page for the Help industry
//The page will contain the industry menu and the transcription box
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.2), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'Lets Yap about Yappy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      'Welcome to Yappy! If this is your first time and need help with using Yappy, please select the button below.',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 1),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                        builder: (context) => TutorialPage(),
                        ),
                      );
                      },
                      child: Text('It\'s my first time'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Reporting a Problem with Yappy\n'
                      'If something is not working on Yappy, please follow the instructions below to let us know.\n\n',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Report a Problem'),
                              content: Text('Please call: +1-800-123-4567'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Close'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Report a problem'),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '\n\nFeedback from the people who use Yappy has helped us redesign our products, improve our policies and fix technical problems. We really appreciate you taking the time to share your thoughts and suggestions with us.\n',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Feedback for the Help Center'),

                            actions: [
                            TextButton(
                              onPressed: () {
                              Navigator.of(context).pop();
                              },
                              child: Text('Close'),
                            ),
                            ],
                          );
                          },
                        );
                      },
                      child: Text('Feedback for the Help Center'),
                    ),
                    SizedBox(height: 20),

                  ],
                ),
              ),  
            ),
          ],
        ),
      ),
    );
  }
}
