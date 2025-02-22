import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/course.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/content_carousel.dart";


//The Page
class AssessmentsView extends StatefulWidget{
  AssessmentsView();

  @override
  State createState(){
    return _AssessmentsState();
  }
}

class _AssessmentsState extends State{


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
    title: 'All Assessments',
    userprofileurl: LmsFactory.getLmsService().profileImage ?? '', // Pass your image URL here
  ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:[
            // Text('All Quizzes', style: TextStyle(fontSize: 64)),
            ContentCarousel('assessment', getAllQuizzes()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:[CreateButton('assessment')]
            )
          ]
        )
      )
    );
  }
}

//Helper function that pulls the quizzes from all the user's courses
List<Quiz>? getAllQuizzes(){
  List<Quiz>? result;
  for (Course c in LmsFactory.getLmsService().courses ?? []){
    result = (result ?? []) + (c.quizzes ?? []);
  }
  if (result == []){
    return null;
  }
  return result;
}
