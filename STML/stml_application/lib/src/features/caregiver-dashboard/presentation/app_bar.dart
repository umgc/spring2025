import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: backgroundColor ?? Colors.blue,
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
                'assets/icons/app_icon.png',
                // Replace this with your icon's path
                fit: BoxFit.contain,
                height: 32, // Adjust the size as needed
              ),
              // Spacing between the icon and title
              Text(title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          Text(
            _currentDate(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),

// Widgets on the right side of the AppBar
      actions: [
// First page icon to navigate back
        IconButton(
          icon: const Icon(
            Icons.settings,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
        ),

// First page icon to navigate back
       /* IconButton(
          icon: const Icon(
            Icons.first_page,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),*/
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
