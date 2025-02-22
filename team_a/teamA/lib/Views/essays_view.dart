import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import 'package:learninglens_app/beans/assignment.dart';
import 'package:learninglens_app/beans/course.dart';
import "package:learninglens_app/Controller/custom_appbar.dart";
import "package:learninglens_app/content_carousel.dart";


//The Page
class EssaysView extends StatefulWidget{
  EssaysView();

  @override
  State createState(){
    return _EssaysState();
  }
}

class _EssaysState extends State{


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(title: 'All Essays', userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:[
            ContentCarousel('essay', getAllEssays()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:[CreateButton('essay')]
            )
          ]
        )
      )
    );
  }
}

//Helper function that pulls the essays from all the user's courses
List<Assignment>? getAllEssays(){
  List<Assignment>? result;
  for (Course c in LmsFactory.getLmsService().courses ?? []){
    result = (result ?? []) + (c.essays ?? []);
  }
  if (result == []){
    return null;
  }
  return result;
}
