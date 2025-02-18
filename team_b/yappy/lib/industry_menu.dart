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
      double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column (
        children: [
          SizedBox(height: 25),
          
          Center(
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
          Row (
            mainAxisAlignment: MainAxisAlignment.center, // Center the row's children
            children: [
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