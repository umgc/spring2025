import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/login_screen.dart';
import 'package:memoryminder/ui/profile_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final TextStyle? titleTextStyle;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.titleTextStyle,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color.fromARGB(255, 2, 63, 129),
      elevation: 0.0,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            // This ensures the Row takes the least amount of space
            children: [
              Image.asset(
                'assets/icons/app_bar_icon_brain.png',
                // Replace this with your icon's path
                fit: BoxFit.contain,
                height: 36, // Adjust the size as needed
              ),
              // Spacing between the icon and title
              SizedBox(width: 6.0),
              Text(title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat')),
            ],
          ),
          Text(
            _currentDate(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          SizedBox(height:5.0),

        ],
      ),

// Widgets on the right side of the AppBar
      actions: [
// First page icon to navigate back


// First page icon to navigate back
         IconButton(
          icon: const Icon(
            Icons.logout,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

String _currentDate() {
  final now = DateTime.now();
  final formatter =
      DateFormat('MMMM dd, yyyy'); // You can customize the format here
  return formatter.format(now);
}

// This centers the title

///////////////////////////
