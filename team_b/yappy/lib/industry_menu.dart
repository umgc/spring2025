import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
                )),
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
                  onPressed: () {},
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
                  onPressed: () {},
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
                    // Creates a database query to get all of the inquiries for the industry.
                    // Replace the following line with the actual database query.
                    //int transcriptCount = await fetchTranscriptCount();

                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        //This could be the code to get the actual data
                        // List<String> transcripts = await fetchTranscripts();

                        //This is a test to make sure it works
                        List<String> transcripts = [
                          'Transcript 1',
                          'Transcript 2'
                        ]; // Example data

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
                                      return ListTile(
                                        title: Text(
                                          transcripts[index],
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              //This is the real code
                                              //return generateTranscript(context, transcripts[index], 'Content of ${transcripts[index]}');
                                              //This is a test to make sure it works
                                              return generateTranscript(
                                                context,
                                                'Transcript',
                                                'Waiter: Good afternoon! Welcome to Bella Bistro. My name is Jake, and I\'ll be your server today. Can I start you off with something to drink?\n\nCustomer: Hi, Jake. Yeah, I’ll have an iced tea, please.\n\nWaiter: Absolutely. Sweetened or unsweetened?\n\nCustomer: Unsweetened, please.\n\nWaiter: Got it. I’ll be right back with that. (Leaves and returns with the drink) Here you go. Have you had a chance to look over the menu?\n\nCustomer: Yeah, I think so. I’m trying to decide between the grilled salmon and the chicken parmesan.\n\nWaiter: Both are great choices! If you’re in the mood for something lighter, the salmon is served with roasted veggies and a lemon butter sauce. The chicken parmesan is heartier, with a side of pasta and garlic bread.\n\nCustomer: Hmm… that lemon butter sauce sounds amazing. Let’s go with the salmon.\n\nWaiter: Excellent choice! Would you like a soup or salad with that?\n\nCustomer: A salad, please. Ranch dressing on the side.\n\nWaiter: Perfect. Would you like to add anything else?\n\nCustomer: No, I think I’m good for now.\n\nWaiter: Sounds good! I’ll get that started for you. Let me know if you need anything else in the meantime.\n\nCustomer: Will do. Thanks!\n\n[Time passes, and the waiter returns with the food.]\n\nWaiter: Here’s your grilled salmon and salad. Can I get you anything else?\n\nCustomer: This looks great! No, I’m all set.\n\nWaiter: Enjoy your meal! Let me know if you need anything.\n\nCustomer: Will do, thanks!',
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
