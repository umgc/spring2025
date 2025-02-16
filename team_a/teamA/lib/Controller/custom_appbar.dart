import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/Views/login_page.dart';
import 'package:learninglens_app/Views/user_settings.dart';
// TODO: Import GoogleCourses widget if it doesn't exist
// import 'package:learninglens_app/Views/google_courses.dart';

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
  String _selectedClassroom = 'Moodle Classroom'; // Default selection

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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TeacherDashboard()),
                      );
                    },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        // Added: Dropdown menu for classroom selection
        DropdownButton<String>(
          value: _selectedClassroom,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedClassroom = newValue;
              });
              if (newValue == 'Google Classroom') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoogleCourses()),
                );
              } else if (newValue == 'Moodle Classroom') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
                print('Navigate to Moodle Classroom');
              }
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
            // Commented: Removed logout functionality
            // onTap: () {
            //   MoodleApiSingleton().logout();
            //   Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => LoginApp()),
            //     (route) => false,
            //   );
            //   print("Profile image clicked!");
            // },
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
}
