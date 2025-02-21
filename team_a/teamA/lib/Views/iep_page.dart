import "package:flutter/material.dart";
import "package:learninglens_app/Api/moodle_api_singleton.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";

class IepPage extends StatefulWidget{
  IepPage();

  @override
  State createState(){
    return _IepPageState();
  }
}

class _IepPageState extends State{
  bool? isChecked1 = false;
  bool? isChecked2 = false;
  bool? isChecked3 = false;
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(title: 'Individual Education Plans', userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Text(
              'Individual Education Plan Page',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            Text(
              'Enroll Student in New IEP',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Container(
              width: 500,
              padding: EdgeInsets.only(top: 20, bottom: 20),
              child: TextField(
                        decoration: InputDecoration(
                        labelText: 'Enter First Name', // Label inside the text box
                        border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              width: 500,
              padding: EdgeInsets.only(bottom: 20),
              child: TextField(
                        decoration: InputDecoration(
                        labelText: 'Enter Last Name', // Label inside the text box
                        border: OutlineInputBorder(),
                ),
              ),
            ),
            DropdownMenu(
              helperText: 'Course',
              width: 500,
              dropdownMenuEntries: <DropdownMenuEntry<Color>>[
                DropdownMenuEntry(value: Colors.red, label: 'red'),
                DropdownMenuEntry(value: Colors.blue, label: 'blue')
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: isChecked1,
                  onChanged: (newBool) {
                    setState(() {
                      isChecked1 = newBool;
                    });
                  },
                ),
                Text('Requires more time on essay assignments.')
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value:isChecked2,
                  onChanged: (newBool) {
                    setState(() {
                      isChecked2 = newBool;
                    });
                  },
                ),
                Text('Requires more time on assessments and quizes.')
              ]
            ),
            Row(
              children: [
                Checkbox(
                  value: isChecked3,
                  onChanged: (newBool) {
                    setState(() {
                      isChecked3 = newBool;
                    });
                  },
                ),
                Text('Requires visual aids on some assignments.')
              ]
            ),
            Container(
              width: 500,
              padding: EdgeInsets.only(bottom: 5),
              child: TextField(
                        decoration: InputDecoration(
                        labelText: 'Additional Comments (Optional)', // Label inside the text box
                        border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: 0, left: 400),
              child: ElevatedButton(
                    onPressed: () {
                      print('Submitted');
              },
                    child: Text('Submit'),
              )
              //test
            ),
          ]
        )
      )
    );
  }
}