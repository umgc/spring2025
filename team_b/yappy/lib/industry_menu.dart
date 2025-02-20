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

  @override
  Widget build(BuildContext context) {

    // Gets the width and height of the current screen
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),

      // Creates a column for the items within the menu
      child: Column (
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

              child: 
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white
                    ), 
                  ),
                )

            ),
          ),
          SizedBox(height: screenHeight * .03),
          
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
                    size: screenHeight * .05,
                  ),
                  onPressed: () {

                  }, 
                ),
              ),
              SizedBox(width: screenWidth * .06),

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
                    size: screenHeight * .05,
                  ),
                  
                  onPressed: () {

                  }, 
                ),
              ),
              SizedBox(width: screenWidth * .06),

              // Creates a transcript button
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
                    size: screenHeight * .05,
                  ),
                  onPressed: () {

                  }, 
                ),
              ),
            ],
          ),
        ]
      )
    );
  }

  
}