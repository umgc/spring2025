import "package:flutter/material.dart";
import "package:learninglens_app/Api/lms/factory/lms_factory.dart";
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
class TemplateView extends StatefulWidget {
  TemplateView();

  @override
  State createState() {
    return _TemplateState();
  }
}

class _TemplateState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
            title: 'Template View',
            onRefresh: () {
              // Add refresh logic here
            },
            userprofileurl: LmsFactory.getLmsService().profileImage ?? ''),
        body: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
              // Add Content here
              Text(
                'Place content here',
                style: TextStyle(fontSize: 20),
              ),
            ])));
  }
}
