import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData icon;

  MenuItem({required this.title, required this.icon});
}
class IndustryMenu extends StatelessWidget {
  final String title;
  final IconData icon;

  const IndustryMenu({required this.title, required this.icon, Key? key}) : super(key: key); 

  Widget generateTranscript(BuildContext context, String title, String content) {
      return Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(title),
                      content: SingleChildScrollView(
                        child: Text(content),
                      ),
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
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }


  @override
  Widget build(BuildContext context) {

      // Gets the width of the current screen
      double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),

      // Creates a column for the items within the menu
      child: Column (
        children: [

          // Adds padding between the navigation menu and the industry menu
          SizedBox(height: 25),
          
          Center(
            // Creates the text box above the icons
            child: Container(
            width: screenWidth * .75,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 67, 67, 67),
            ),
            padding: EdgeInsets.all(12),

              child: 
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white
                    ), 
                  ),
                )

            ),
          ),
          SizedBox(height: 25),
          
          // Creates a row of clickable menu icons
          Row (
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Creates the chat button for each menu
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey
                ),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {

                  }, 
                ),
              ),
              SizedBox(width: 40),

              // Creates a industry specific icon based on user input
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey
                ),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    icon,
                    color: Colors.white,
                    size: 40,
                  ),
                  
                  onPressed: () {

                  }, 
                ),
              ),
              SizedBox(width: 40),

              // Creates a transcript history button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey
                ),
                padding: EdgeInsets.all(5),
                child: IconButton(
                  icon: Icon(
                    Icons.file_copy,
                    color: Colors.white,
                    size: 40,
                  ),
                    onPressed: () {

                    // Creates a database query to get all of the inquiries for the industry.
                      FutureBuilder<int>(
                      future: Future.value(2), // Simulating a database query returning 2 transcripts
                      //add the correct database query here.
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          int transcriptCount = snapshot.data ?? 0;
                          List<Widget> transcriptWidgets = List.generate(transcriptCount, (index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return generateTranscript(context, 'Transcript $index', 'Content of transcript $index');
                                      },
                                    );
                                  },
                                  child: Icon(
                                    Icons.description,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          });
                          return Row(children: transcriptWidgets);
                        }
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
