import 'package:flutter/material.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/login_page.dart';
import 'package:learninglens_app/Views/user_settings.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userprofileurl;

  CustomAppBar({required this.title, required this.userprofileurl});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      centerTitle: true, // Ensures the title stays centered
      leading: Row(
        mainAxisSize: MainAxisSize.min, // Ensures the row doesn’t take all available space
        children: [
          Flexible(
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed:  isDashboard(context) ? null : () {
                Navigator.pop(context); // Navigate back
              },
            ),
          ),
          Flexible(
            child: IconButton(
              icon: Icon(Icons.home),
              // if the current page is the dashboard, do nothing
              onPressed: isDashboard(context) ? null : () {
                // Navigate to the TeacherDashboardr
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherDashboard()),
                );
              },
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: !isDashboard(context) ? null : () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserSettings()),
            );
          },
        ),
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: InkWell(
        // remove the logout button 
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
            userprofileurl,
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

  /**
   * Check if the current page is the dashboard
   */
  bool isDashboard(BuildContext context) {
    return title == 'Learning Lens';// TODO: there has to be a better reference to the dashboard view...
  }

  // This is required to implement PreferredSizeWidget
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
