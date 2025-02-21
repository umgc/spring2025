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

// if resturant load the correct code. 

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

                    //on pressed the code needs to refresh and recognize what industry is selected. 

                    //get cookie 
                    //when the page reopens the coockie will load the correct information. 

                  }, 
                ),
              ),
              SizedBox(width: 40),

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
                    size: 40,
                  ),
                    onPressed: () {
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
                                GestureDetector(
                                onTap: () {
                                  showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                    title: Text('20 Feb 2025 - Transcript 1'),
                                    content: Text('This is the content of Transcript 1.\nHere is the second line.'),
                                    actions: [
                                      //add the export things
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
                                  'Transcript 1',
                                  style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  ),
                                ),
                                ),  
                                SizedBox(height: 20),
                                GestureDetector(
                                onTap: () {
                                    showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                    title: Text('20 Feb 2025 - Transcript 2'),
                                    content: SingleChildScrollView(
                                      child: Text(
                                      'Waiter: Good afternoon! Welcome to Bella Bistro. My name is Jake, and I\'ll be your server today. Can I start you off with something to drink?\n\nCustomer: Hi, Jake. Yeah, I’ll have an iced tea, please.\n\nWaiter: Absolutely. Sweetened or unsweetened?\n\nCustomer: Unsweetened, please.\n\nWaiter: Got it. I’ll be right back with that. (Leaves and returns with the drink) Here you go. Have you had a chance to look over the menu?\n\nCustomer: Yeah, I think so. I’m trying to decide between the grilled salmon and the chicken parmesan.\n\nWaiter: Both are great choices! If you’re in the mood for something lighter, the salmon is served with roasted veggies and a lemon butter sauce. The chicken parmesan is heartier, with a side of pasta and garlic bread.\n\nCustomer: Hmm… that lemon butter sauce sounds amazing. Let’s go with the salmon.\n\nWaiter: Excellent choice! Would you like a soup or salad with that?\n\nCustomer: A salad, please. Ranch dressing on the side.\n\nWaiter: Perfect. Would you like to add anything else?\n\nCustomer: No, I think I’m good for now.\n\nWaiter: Sounds good! I’ll get that started for you. Let me know if you need anything else in the meantime.\n\nCustomer: Will do. Thanks!\n\n[Time passes, and the waiter returns with the food.]\n\nWaiter: Here’s your grilled salmon and salad. Can I get you anything else?\n\nCustomer: This looks great! No, I’m all set.\n\nWaiter: Enjoy your meal! Let me know if you need anything.\n\nCustomer: Will do, thanks!',
                                      ),
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
                                  'Transcript 2',
                                  style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  ),
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
