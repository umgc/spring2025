import "package:flutter/material.dart";
import "package:learninglens_app/Api/moodle_api_singleton.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";

///
/// Template for views
/// Need to change the class name to the name based on the view you 
/// are creating to include the constructor as well. 
/// Need to change the class that extends State as well. Make sure
/// that the createState function returns the same name. 
/// 
/// The CustomAppBar is already included, but you will need to update
/// the title string. 
/// 
/// The content for the page begins in the children array. There is 
/// a single text box as a place holder. 
/// 
/// To add your view to the rest of the app, you will have to add it
/// to the dashboard.dart file. On line ~213, there is a List called
/// buttonData. You will need to update the 'onPressed' section with 
/// your new template. You can see examples that Derek has already 
/// done on other buttons. 
///
class LessonPlans extends StatefulWidget{
  LessonPlans();

  @override
  State createState(){
    return _LessonPlanState();
  }
}

class _LessonPlanState extends State{

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(title: 'Lesson Plans', userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: SingleChildScrollView(
        child: Row(
          children: [
            // Left side - Add New Lesson Plan
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Lesson Plan',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Lesson Plan Name
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Lesson Plan Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Course Combo Box
                    DropdownButtonFormField<String>(
                      value: null, //should be selectedCourse
                      items: List.empty(), //should be a list of courses
                      onChanged: (value) {
                        setState(() {
                          null; //when user changes combo box change selectedcourse
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 10),

                    // File Upload Section
                    ElevatedButton(
                      onPressed: () {
                        // NEED TO ADD LOGIC!
                      },
                      child: Text('Upload Lesson Plan File'),
                    ),

                    // OR Label
                    Center(
                      child: Text(
                        '- OR -',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Enter Lesson Plan Manually
                    TextField(
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Enter Lesson Plan Manually',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        // Submit logic here
                      },
                      child: Text('SUBMIT'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 20),

            // Right side - Existing Lesson Plans
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Existing Lesson Plans',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Table Frame
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Lesson Plan Name')),
                        DataColumn(label: Text('Course')),
                        DataColumn(label: Text('Attached File?')),
                        DataColumn(label: Text('Select')),
                      ],
                      rows: [
                        // Example row data
                        DataRow(cells: [
                          DataCell(Text('Plan 1')),
                          DataCell(Text('Course 1')),
                          DataCell(Text('Yes')),
                          DataCell(Checkbox(value: false, onChanged: (bool? value) {})),
                        ]),
                        DataRow(cells: [
                          DataCell(Text('Plan 2')),
                          DataCell(Text('Course 2')),
                          DataCell(Text('No')),
                          DataCell(Checkbox(value: false, onChanged: (bool? value) {})),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // DELETE and SHOW buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Delete selected logic
                        },
                        child: Text('DELETE SELECTED'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Show selected logic
                        },
                        child: Text('SHOW SELECTED'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }
}
