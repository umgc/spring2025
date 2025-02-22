import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
import "package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart";
import "package:learninglens_app/Controller/custom_appbar.dart";

class IepPage extends StatefulWidget{
  IepPage();

  @override
  State createState(){
    return _IepPageState();
  }
}

class _IepPageState extends State{

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(title: 'Individual Education Plans', userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:[
            // Add Content here
            Text(
              'Place content here',
              style: TextStyle(fontSize: 20),
            ),
          ]
        )
      )
    );
  }
}