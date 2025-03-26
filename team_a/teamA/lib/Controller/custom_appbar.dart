import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/experimental/assistant/textbased_function_caller_view.dart';
import 'package:learninglens_app/Api/lms/enum/lms_enum.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/user_settings.dart';
import 'package:learninglens_app/Views/chat_screen.dart';
import 'package:learninglens_app/services/local_storage_service.dart';

class ClassroomSelection {
  static LmsType selectedClassroom = LocalStorageService.getSelectedClassroom() == LmsType.MOODLE
      ? LmsType.MOODLE
      : LmsType.GOOGLE;
}

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String userprofileurl;
  final VoidCallback? onRefresh; // Optional refresh callback

  CustomAppBar({required this.title, required this.userprofileurl, this.onRefresh});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final bool canAccessApp = canUserAccessApp(context);

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(
        widget.title,
        textAlign: TextAlign.center,
      ),
      centerTitle: true,
      leadingWidth: 120,
      leading: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
          Flexible(
            child: IconButton(
              icon: Icon(Icons.chat_rounded),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen()
                  )
                );
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[

        Flexible(
            child: IconButton(
              icon: Icon(Icons.science), // Science Icon
              onPressed: !canAccessApp
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TextBasedFunctionCallerView()),
                );
              },
            ),
          ),
        // Refresh button: Instead of relying on an external callback,
        // try to obtain the current route's name and then replace the route,
        // effectively refreshing the current view.
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () {
            final currentRouteName = ModalRoute.of(context)?.settings.name;
            if (currentRouteName != null) {
              Navigator.pushReplacementNamed(context, currentRouteName);
            } else {
              // Fallback: if no route name is available, call the provided onRefresh callback if any.
              widget.onRefresh?.call();
            }
          },
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<LmsType>(
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
                : null,
            items: LmsType.values.map<DropdownMenuItem<LmsType>>((LmsType value) {
              return DropdownMenuItem<LmsType>(
                value: value,
                child: Text(
                  value == LmsType.GOOGLE ? 'Google Classroom' : 'Moodle Classroom',
                ),
              );
            }).toList(),
          ),
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
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      // print('Image load error: $error');
                      // Just display the account_circle icon be default
                      return Icon(Icons.account_circle, size: 50);
                    },
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
    if (ClassroomSelection.selectedClassroom == LmsType.GOOGLE) {
      LocalStorageService.saveSelectedClassroom(LmsType.GOOGLE);
    } else {
      LocalStorageService.saveSelectedClassroom(LmsType.MOODLE);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDashboard(),
        // builder: (context) => ClassroomSelection.selectedClassroom == LmsType.GOOGLE
        //     // ? GoogleTeacherDashboard()
        //     ? TeacherDashboard()
        //     : TeacherDashboard(),
      ),
    );
  }


  bool canUserAccessApp(BuildContext context) {
    return LocalStorageService.canUserAccessApp();
  }

  String getClassroom() {
    return LocalStorageService.getClassroom();
  }

  bool isMoodle() {
    return LocalStorageService.isMoodle();
  }
}
