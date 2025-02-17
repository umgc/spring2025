import 'package:flutter/material.dart';

// Defines a reusable Hamburger Menu Widget
class HamburgerMenu extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
      return Drawer(
        width: 175,
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerItem('Restaurant', context, IndustryPage(title: 'Restaurant')),
            _buildDrawerItem('Mechanical Aid', context, IndustryPage(title: 'Mechanical Aid')),
            _buildDrawerItem('Medical Doctor', context, IndustryPage(title: 'Medical Doctor')),
            _buildDrawerItem('Medical Patient', context, IndustryPage(title: 'Medical Patient')),
            _buildDrawerItem('Help', context, IndustryPage(title: 'Help')),
            _buildDrawerItem('Contact', context, IndustryPage(title: 'Contact')),
          ],
        ),
      );
  }

  Widget _buildDrawerItem(String title, BuildContext context, Widget page) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: Colors.white,
      tileColor: const Color.fromARGB(255, 54, 54, 54),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }
  
}

class IndustryPage extends StatelessWidget {
  final String title;

  const IndustryPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Page')),
    );
  }
}