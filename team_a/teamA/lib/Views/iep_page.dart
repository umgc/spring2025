import "package:flutter/material.dart";
import 'package:flutter_quill/flutter_quill.dart';
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/quiz_override';
import 'package:learninglens_app/services/api_service.dart';

class IepPage extends StatefulWidget{
  IepPage();

  @override
  State createState(){
    return _IepPageState();
  }
}

class _IepPageState extends State{
  TextEditingController _dateController = TextEditingController();
  bool? isChecked1 = false;
  bool? isChecked2 = false;
  String? selectedCourse;
  String? selectedAssignment;
  String? selectedEssay;
  int? quizId;
  int? userId;
  int? newEndTime;
  String selectedDate = 'Select a Date';
  Future<List<Participant>>? participants;
  Future<List<Assignment>>? essay;
  Future<List<Quiz>>? quiz;
  List<String> type = ['Quiz', 'Essay'];
  double? epochTime;
  List<String> attempts = ['Unlimited', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int? selectedAttempt;



 void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),);
    if (picked!= null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
        epochTime = picked.millisecondsSinceEpoch/1000.round();
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Individual Education Plans',
        onRefresh: () {
          // _loadCourses();
        },
        userprofileurl: LmsFactory.getLmsService().profileImage ?? ''
        ),
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
                DropdownMenu(
                  helperText: 'Course',
                  hintText: 'Select Course',
                  width: 500,
                  dropdownMenuEntries: (getAllCourses() ?? []).map((Course course) {
                    return DropdownMenuEntry<String>(
                      value: course.id.toString(),
                      label: course.fullName,
                    );
                  }).toList(),
                  onSelected: (String? selectedValue) {
                    setState(() {
                      selectedCourse = selectedValue;
                    });
                    participants = handleSelection(selectedValue);
                    if (selectedValue !=null) {
                      essay = handleEssaySelection(int.parse(selectedValue));
                    }
                    else {
                      print('Selected Value is Null');
                    }
                    if (selectedValue != null) {
                      quiz = handleQuizSelection(int.parse(selectedValue));
                    }
                    else {
                      print('Selected Value is Null');
                    }
                  },
                ),
                Visibility(
                  visible: selectedCourse != null,
                  child: FutureBuilder<List<Participant>>(
                  future: participants,
                  builder: (BuildContext context, AsyncSnapshot<List<Participant>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Show a loading spinner while fetching
                      } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}'); // Handle error
                      } else if (snapshot.hasData) {
                        List<DropdownMenuEntry<String>> dropdownEntries = snapshot.data!.map((Participant participant){
                          return DropdownMenuEntry<String>(
                            value: participant.id.toString(),
                            label: participant.fullname,
                          );
                        }).toList();
                      return DropdownMenu(
                        helperText: 'Participants',
                        hintText: 'Select Participants',
                        width: 500,
                        dropdownMenuEntries: dropdownEntries,
                        onSelected: (String? selectedParticipant) {
                          setState(() {
                            if (selectedParticipant != null) {
                              userId = int.parse(selectedParticipant);
                            }
                            else {
                              print('No Participants were selected');
                            }
                          });
                        },
                      );
                      } else {
                        return DropdownMenu(
                          hintText: 'Select A Course To View Participants',
                          helperText: 'Participants',
                          width: 500,
                          dropdownMenuEntries: [],
                        );
                      }
                  },
                ),
                ),
                Visibility (
                  visible: userId != null,
                  child: DropdownMenu(
                  width: 500,
                  helperText: 'Assignment',
                  hintText: 'Select Quiz or Essay',
                  dropdownMenuEntries: type.map<DropdownMenuEntry<String>>((String value) {
                    return DropdownMenuEntry<String>(
                      value: value,
                      label: value,
                    );
                  }).toList(),
                  onSelected: (String? selectedValue) {
                    setState(() {
                      selectedAssignment = selectedValue;
                    });
                    if (selectedAssignment == 'Essay') {
                      if (selectedCourse != null) {
                        handleEssaySelection(int.parse(selectedCourse!));
                      }
                      else {
                        print('Selected Course Is Null');
                      }
                    }
                  },
                ),
                ),
                Visibility(
                  visible: selectedAssignment == 'Essay',
                  child: FutureBuilder<List<Assignment>>(
                  future: essay,
                  builder: (BuildContext context, AsyncSnapshot<List<Assignment>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Show a loading spinner while fetching
                      } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}'); // Handle error
                      } else if (snapshot.hasData) {
                        List<DropdownMenuEntry<String>> dropdownEntries = snapshot.data!.map((Assignment assignment){
                          return DropdownMenuEntry<String>(
                            value: assignment.name,
                            label: assignment.name,
                          );
                        }).toList();
                      return DropdownMenu(
                        helperText: 'Essays',
                        hintText: 'Select Essay',
                        width: 500,
                        dropdownMenuEntries: dropdownEntries,
                      );
                      } else {
                        return DropdownMenu(
                          hintText: 'Select A Course To View Essays',
                          helperText: 'Essays',
                          width: 500,
                          dropdownMenuEntries: [],
                        );
                      }
                  },
                ),
                ),
                Visibility(
                  visible: selectedAssignment == 'Quiz',
                  child: FutureBuilder<List<Quiz>>(
                  future: quiz,
                  builder: (BuildContext context, AsyncSnapshot<List<Quiz>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // Show a loading spinner while fetching
                      } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}'); // Handle error
                      } else if (snapshot.hasData) {
                        List<DropdownMenuEntry<String>> dropdownEntries = snapshot.data!.map((Quiz quiz){
                          return DropdownMenuEntry<String>(
                            value: quiz.id.toString(),
                            label: quiz.name!,
                          );
                        }).toList();
                      return DropdownMenu(
                        helperText: 'Quiz',
                        hintText: 'Select Quiz',
                        width: 500,
                        dropdownMenuEntries: dropdownEntries,
                        onSelected: (String? selectedQuizId) {
                          setState(() {
                            if (selectedQuizId != null) {
                              quizId = int.parse(selectedQuizId);
                            }
                            else {
                              print ('Quiz Id is null');
                            }
                          });
                        },
                      );
                      } else {
                        return DropdownMenu(
                          hintText: 'Select A Course To View Quizzes',
                          helperText: 'Quizzes',
                          width: 500,
                          dropdownMenuEntries: [],
                        );
                      }
                  },
                ),
                ),
                Visibility(
                  visible: quizId != null,
                  child: DropdownMenu(
                    width: 300,
                    helperText: 'Attempts',
                    hintText: 'Select Number of Attempts',
                    dropdownMenuEntries: attempts.map<DropdownMenuEntry<String>>((String attempts) {
                      return DropdownMenuEntry<String>(
                        value: attempts,
                        label: attempts,
                    );
                  }).toList(),
                  onSelected: (String? selectedValue) {
                    setState(() {
                      if (selectedValue == 'Unlimited') {
                        selectedAttempt = 0;
                      }
                      else {
                        selectedAttempt = int.parse(selectedValue!);
                      }
                    });
                  },
                ),
              ),
                Visibility(
                  visible: selectedAttempt != null,
                  child: Row (children: [
                    Container(
                      width: 325,
                      margin: EdgeInsets.only(right: 20),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(_dateController.text, style: TextStyle(fontSize: 20)),
                    ),
                    GestureDetector(
                      onTap:() => _selectDate(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Select Date',
                        ),
                      ),
                    ),
                    ] ,
                  ), 
                ),
                Visibility(
                  visible: epochTime != null,
                  child: Container(                  
                    padding: EdgeInsets.only(top: 50, left: 200),
                    child: ElevatedButton(
                      onPressed: () {
                        quizOver(epochTime, quizId, userId, selectedAttempt);
                      },
                      child: Text('Submit')
                    )
                  )
                ),
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
                        DataColumn(label: Text('Assignment Name')),
                        DataColumn(label: Text('Original Due Date')),
                        DataColumn(label: Text('Extended Due Date')),
                        DataColumn(label: Text('Additional Comments')),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Text('Andrew Hammes')),
                            DataCell(Text('Bio')),
                            DataCell(Text('Yes')),
                            DataCell(Text('No')),
                            DataCell(Text('Yes')),
                            DataCell(ConstrainedBox(constraints: BoxConstraints(maxWidth:225,), child: Text('Student is not very smart. This is what wrapped text would look like. Still need to work out all the bugs.', softWrap: true, maxLines: null, overflow: TextOverflow.visible))),
                          ]
                        ),
                      ],
                      dataRowHeight: 200,
                    )
                  ),
                ),
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
  result = MoodleLmsService().courses;
  return result;
}

//loads participants for the drop down menu
Future<List<Participant>>? getAllParticipants(String courseID) async {
  List<Participant>? participants;
  participants = await MoodleLmsService().getCourseParticipants(courseID);
  return participants;
}

//loads participants for drop down menus depending on Course Selected
Future<List<Participant>> handleSelection(String? courseID) async {
  if (courseID != null) {
    List<Participant>? participants = await getAllParticipants(courseID);
    if (participants == null) {
      return [];
    }
    else {
      return participants;
    }
  }
  else {
    print('Course ID was Null.');
    return [];
  }
}

Future<List<Assignment>> handleEssaySelection(int? courseID) async {
  if (courseID != null) {
    List<Assignment>? essays = await MoodleLmsService().getEssays(courseID);
    if (essays == null) {
      return [];
    }
    else {
      return essays;
    }
  }
  else {
    return [];
  }
}

Future<List<Quiz>> handleQuizSelection(int? courseID) async {
  if (courseID != null) {
    List<Quiz>? quizzes = await MoodleLmsService().getQuizzes(courseID);
    if (quizzes == null) {
      return [];
    }
    else {
      return quizzes;
    }
  }
  else {
    return [];
  }
}

void quizOver(epochTime, quizId, userId, attempts) async {
  QuizOverride override = await MoodleLmsService().addQuizOverride(quizId: quizId, userId: userId, timeClose: epochTime, attempts: attempts);
}
