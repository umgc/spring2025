import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";
import 'package:learninglens_app/beans/course.dart';
import 'package:learninglens_app/beans/participant.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/quiz_override';
import 'package:learninglens_app/beans/override.dart';


class IepPage extends StatefulWidget{
  IepPage();

  @override
  State createState(){
    return _IepPageState();
  }
}

class _IepPageState extends State{
  TextEditingController _dateController = TextEditingController();
  TextEditingController _cutoffDateController = TextEditingController();
  bool? isChecked1 = false;
  bool? isChecked2 = false;
  String? selectedCourse;
  String? selectedAssignment;
  String? selectedEssay;
  int? essayId;
  int? quizId;
  int? userId;
  int? newEndTime;
  String selectedDate = 'Select a Date';
  Future<List<Participant>>? participants;
  Future<List<Assignment>>? essay;
  Future<List<Quiz>>? quiz;
  List<String> type = ['Quiz', 'Essay'];
  double? epochTime;
  double? epochTime2;
  List<String> attempts = ['Unlimited', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  int? selectedAttempt;

//function used to select extended due date for override
 void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),);
    if (picked!= null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = "${picked.toLocal()}".split(' ')[0];
        epochTime = picked.millisecondsSinceEpoch/1000.round();
      });
    }
  }

//function used to select cut off date for the essay override
   void _selectCutOffDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),);
    if (picked!= null && picked != DateTime.now()) {
      setState(() {
        _cutoffDateController.text = "${picked.toLocal()}".split(' ')[0];
        epochTime2 = picked.millisecondsSinceEpoch/1000.round();
      });
    }
  }

  void _getAssignmentOverride() async {
    await MoodleLmsService().getAssignmentOverrides();
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
                //Text(getOverrides().toString()),
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
                  width: 350,
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
                        width: 350,
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
                          width: 350,
                          dropdownMenuEntries: [],
                        );
                      }
                  },
                ),
                ),
                Visibility (
                  visible: userId != null,
                  child: DropdownMenu(
                  width: 350,
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
                            value: assignment.id.toString(),
                            label: assignment.name,
                          );
                        }).toList();
                      return DropdownMenu(
                        helperText: 'Essays',
                        hintText: 'Select Essay',
                        width: 350,
                        dropdownMenuEntries: dropdownEntries,
                        onSelected: (String? selectedEssayId){
                          setState(() {
                            if (selectedEssayId != null) {
                              essayId = int.parse(selectedEssayId);
                            }
                            else {
                              print('Essay ID was Null');
                            }
                          });
                        },
                      );
                      } else {
                        return DropdownMenu(
                          hintText: 'Select A Course To View Essays',
                          helperText: 'Essays',
                          width: 350,
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
                        width: 350,
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
                          width: 350,
                          dropdownMenuEntries: [],
                        );
                      }
                  },
                ),
                ),
                Visibility(
                  visible: quizId != null,
                  child: DropdownMenu(
                    width: 350,
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
                      width: 250,
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
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
                  visible: essayId != null,
                  child: Row (children: [
                    Container(
                      width: 250,
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
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Select Due Date',
                        ),
                      ),
                    ),
                    ] ,
                  ),
                ),
                Visibility(
                  visible: essayId != null,
                  child: Row (children: [
                    Container(
                      width: 250,
                      margin: EdgeInsets.only(right: 20, top: 20),
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(_cutoffDateController.text, style: TextStyle(fontSize: 20)),
                    ),
                    GestureDetector(
                      onTap:() => _selectCutOffDate(context),
                      child: Container(
                        margin: EdgeInsets.only(top:20),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Select Cutoff Date',
                        ),
                      ),
                    ),
                  ],)
                ),
                Visibility(
                  visible: epochTime != null,
                  child: Container(                  
                    padding: EdgeInsets.only(top: 50, left: 160),
                    child: ElevatedButton(
                      onPressed: () {
                        if(selectedAssignment == 'Quiz') {
                          quizOver(epochTime, quizId, userId, selectedAttempt);
                          //_getAssignmentOverride();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => IepPage()));
                        }
                        else if(selectedAssignment == 'Essay'){
                          essayOver(epochTime, essayId, userId, epochTime2);
                          //_getAssignmentOverride();
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => IepPage()));

                        }
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
                  margin: EdgeInsets.only(left: 20),
                  width: 1100,
                  height: 830,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(const Color.fromARGB(255, 77, 195, 89)),
                        columns: [
                          DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Course Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Assignment Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Assignment Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Extended Due Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Cut Off Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          DataColumn(label: Text('Attempts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        ],
                        //rows: (getOverrides() ?? []).map(buildDataRow).toList(),
                        rows: (getOverrides() ?? []).asMap().map((index, override) {
                          return MapEntry(index, buildDataRow(override, index),
                          );
                        }).values.toList(),
                      ),  
                    ), 
                  ),
                ),
              ]
            ),
          ],      
        ),
      ),
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

//gets the list of Essays dependent on Course
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

//gets the list of quizzes dependent on Course
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

//Quiz Override function
void quizOver(epochTime, quizId, userId, attempts) async {
  QuizOverride override = await MoodleLmsService().addQuizOverride(quizId: quizId, userId: userId, timeClose: epochTime, attempts: attempts);
  print('Override: $override');
}

//Essay Override functioon
void essayOver(epochTime, essayId, userId, epochTime2) async {
  String essayOverride = await MoodleLmsService().addEssayOverride(assignid: essayId, userId: userId, dueDate: epochTime, cutoffDate: epochTime2);
  print('Override: $essayOverride');
}

//function used to load the table and retrieve all overrides
List<Override>? getOverrides() {
  List<Override>? overrides;
  overrides = MoodleLmsService().overrides;
  return overrides;
}

//builds the rows for the table. Used in DataTable widget
DataRow buildDataRow(Override override, int index) {
  return DataRow(
    color: MaterialStateProperty.resolveWith<Color>((states) {
      return index % 2 == 0 ? Colors.grey[400]! : Colors.white;
    }),
    cells: [
      DataCell(Text(override.fullname)),
      DataCell(Text(override.courseName)),
      DataCell(Text(override.assignmentName)),
      DataCell(Text(override.type)),
      DataCell(Text(override.endTime?.toString() ?? 'N/A')),
      DataCell(Text(override.cutoffTime?.toString() ?? 'N/A')),
      DataCell(Text(override.attempts?.toString() ?? 'N/A')),
    ],
  );
}