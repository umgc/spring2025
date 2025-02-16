import 'package:flutter/material.dart';
import 'package:yappy/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },        
        ),
        toolbarHeight: 140,
        title: Center(
          child: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            radius: 140,
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 140,
              height: 140,
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white),
            onPressed: () {
              Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to Login  
              );
            },
          ),
        ],
      ),
            // Hamburger Menu (Drawer)
      drawer: Drawer(
        width: 150,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerItem('Restaurant'),
            _buildDrawerItem('Mechanic'),
            _buildDrawerItem('Medical'),
            _buildDrawerItem('Help'),
            _buildDrawerItem('Contact'),
            _buildDrawerItem('Log Out'),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.white60),
                  hintText: 'Search conversations',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            _buildButton('Restaurant'),
            _buildButton('Mechanic'),
            _buildButton('Medical'),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      textColor: Colors.white,
      tileColor: const Color.fromARGB(255, 54, 54, 54),
      title: Text(title),
      onTap: () {
        // TODO Navigate to the corresponding screen
      },
    );
  }
}

