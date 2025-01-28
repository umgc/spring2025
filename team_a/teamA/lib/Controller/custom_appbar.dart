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
              onPressed: () {
                Navigator.pop(context); // Navigate back
              },
            ),
          ),
          Flexible(
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // Navigate to the TeacherDashboard
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
          onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserSettings()),
        );
          },
        ),
        Padding(
          padding: EdgeInsets.only(right: 10.0),
          child: InkWell(
        onTap: () {
          MoodleApiSingleton().logout();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginApp()),
            (route) => false,
          );
          print("Profile image clicked!");
        },
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

  // This is required to implement PreferredSizeWidget
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}


class ThemeNotifier extends ChangeNotifier {
  Color _primaryColor = Colors.deepPurple;

  Color get primaryColor => _primaryColor;

  void updateTheme(Color color) {
    _primaryColor = color;
    print('Theme updated to: $color');
    notifyListeners();  // Notify listeners (like the whole app) to rebuild
  }
}
