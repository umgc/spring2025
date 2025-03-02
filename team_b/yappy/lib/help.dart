import 'package:flutter/material.dart';
import 'package:yappy/tool_bar.dart';


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
        preferredSize: Size.fromHeight(140), 
        child: ToolBar()
      ),
      drawer: HamburgerDrawer(),
            body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.center,
              child: Text(//This text is displayed on the help page
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
                  Text(//This text is displayed on the help page
                    'Reporting a Problem with Yappy\n'
                    'Something Isn\'t Working\n'
                    'If something isn\'t working on Yappy, please follow the instructions below to let us know.\n\n'
                    'Give Us Feedback\n'
                    'Use the links below to give us feedback about how a Yappy feature works or to let us know how we can improve the Help Center:\n\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
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
                SizedBox(height: 10),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Feedback for the Help Center'),
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
                    child: Text('Feedback for the Help Center'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '\n\nFeedback from the people who use Yappy has helped us redesign our products, improve our policies and fix technical problems. We really appreciate you taking the time to share your thoughts and suggestions with us.\n',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),  
          ),
        ],
      ),
    );
  } 
}
