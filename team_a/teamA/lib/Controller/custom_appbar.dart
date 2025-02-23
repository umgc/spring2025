import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_dashboard.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ClassroomSelection {
  static LmsType selectedClassroom = LocalStorageService.getSelectedClassroom() == LmsType.MOODLE ? LmsType.MOODLE : LmsType.GOOGLE;
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
        DropdownButton<LmsType>(
          value: ClassroomSelection.selectedClassroom,
          onChanged: isDashboard(context)
              ? (LmsType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      ClassroomSelection.selectedClassroom = newValue;
                    });
                    navigateToSelectedDashboard(context);
                  }
                }
              : null, // Disable dropdown if not on dashboard
          items: LmsType.values.map<DropdownMenuItem<LmsType>>((LmsType value) {
            return DropdownMenuItem<LmsType>(
              value: value,
              child: Text(value == LmsType.GOOGLE ? 'Google Classroom' : 'Moodle Classroom'),
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

    // set local storage state
    if(ClassroomSelection.selectedClassroom == LmsType.GOOGLE){
      LocalStorageService.saveSelectedClassroom(LmsType.GOOGLE);
    } else {
      LocalStorageService.saveSelectedClassroom(LmsType.MOODLE);
    }

    // navigate the selected dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomSelection.selectedClassroom == LmsType.GOOGLE
            ? GoogleTeacherDashboard()
            : TeacherDashboard(),
      ),
    );
  }
}
