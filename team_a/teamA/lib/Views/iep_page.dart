import "package:flutter/material.dart";
import "package:learninglens_app/Api/moodle_api_singleton.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import 'package:learninglens_app/beans/course.dart';

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      labelText: 'Enter First Name',
                      border: OutlineInputBorder(),
                    )
                  )
                ),
                Container(
                  width: 500,
                  padding: EdgeInsets.only(bottom: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Enter Last Name',
                      border: OutlineInputBorder(),
                    )
                  )
                ),
                DropdownMenu(
                  helperText: 'Course',
                  width: 500,
                  dropdownMenuEntries: (getAllCourses() ?? []).map((Course course) {
                    return DropdownMenuEntry<String>(
                      value: course.fullName,
                      label: course.fullName,
                    );
                  }).toList(),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isChecked1,
                      onChanged: (newBool) {
                        setState((){
                          isChecked1 = newBool;
                        });
                      }
                    ),
                    Text('Requires more time on essay assignments.')
                  ]
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isChecked2,
                      onChanged: (newBool) {
                        setState((){
                          isChecked2 = newBool;
                        });
                      }
                    ),
                    Text('Requires more time on assessments and quizes.')
                  ]
                ),
                Row(
                  children: [
                    Checkbox(
                      value: isChecked3,
                      onChanged: (newBool) {
                        setState((){
                          isChecked3 = newBool;
                        });
                      }
                    ),
                    Text('Requires visual aids on some assignments.')
                  ]
                ),
                Container(
                  width: 500,
                  padding: EdgeInsets.only(bottom: 5),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Additional Comments (Optional)',
                      border: OutlineInputBorder()
                    )
                  )
                ),
                Container(
                  padding: EdgeInsets.only(top: 0, left: 400),
                  child: ElevatedButton(
                    onPressed: () {
                      print('Submitted');
                    },
                    child: Text('Submit')  
                  )
                )
              ]
            ),
            Column(
              children: [
                Text('Existing IEPs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Container(
                  margin: EdgeInsets.only(left: 50),
                  height: 830,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey),
                      columns: [
                        DataColumn(label: Text('Student Name')),
                        DataColumn(label: Text('Course')),
                        DataColumn(label: Text('Extra Time For Essays')),
                        DataColumn(label: Text('Extra Time For Quizzes')),
                        DataColumn(label: Text('Visual Aids')),
                        DataColumn(label: Text('Additional Comments')),
                        DataColumn(label: Text('Select')),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth:225,), child: Text('Student is not very smart. This is what wrapped text would look like. Still need to work out all the bugs.', softWrap: true, maxLines: null, overflow: TextOverflow.visible))),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                                                DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('BIO 547')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(Text('Student is not very smart.')),
                            DataCell(Text('Select')),
                          ]
                        ),
                      ],
                      dataRowHeight: 200,
                    )
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(top: 10, left: 1000),
                  child: ElevatedButton(
                    onPressed: () {
                      print('Deleted');
                    },
                    child: Text('Delete Selected IEP')  
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}

//loads courses for drop down menu.
List<Course>? getAllCourses() {
  List<Course>? result;
  result = MoodleApiSingleton().moodleCourses;
  return result;
}