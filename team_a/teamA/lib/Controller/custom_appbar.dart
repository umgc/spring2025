import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/Views/g_dashboard.dart';
import 'package:learninglens_app/Views/login_page.dart';
import 'package:learninglens_app/Views/user_settings.dart';

class ClassroomSelection {
  static String selectedClassroom = 'Google Classroom';
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String userprofileurl;

  CustomAppBar({required this.title, required this.userprofileurl});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String _selectedClassroom = 'Google Classroom'; // Default selection

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: isDashboard(context)
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
            ),
          ),
          Flexible(
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: isDashboard(context)
                  ? null
                  : () {
                      navigateToSelectedDashboard(context);
                    },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        DropdownButton<String>(
          //value: _selectedClassroom,
          value: ClassroomSelection.selectedClassroom,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedClassroom = newValue;
              });
              navigateToSelectedDashboard(context);
            }
          },
          items: <String>['Moodle Classroom', 'Google Classroom']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: !isDashboard(context)
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserSettings()),
                  );
                },
        ),
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: InkWell(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.userprofileurl,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool isDashboard(BuildContext context) {
    return widget.title == 'Learning Lens';
  }

  void navigateToSelectedDashboard(BuildContext context) {
    if (_selectedClassroom == 'Google Classroom') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GoogleTeacherDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherDashboard()),
      );
    }
  }
}
