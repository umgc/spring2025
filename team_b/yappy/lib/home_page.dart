import 'package:flutter/material.dart';
import 'package:yappy/login_page.dart';

class RestaurantPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restaurant')),
      body: Center(child: Text('Restaurant Page')),
    );
  }
}

class MechanicalAidPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mechanical Aid')),
      body: Center(child: Text('Mechanical Aid Page')),
    );
  }
}

class MedicalDoctorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Medical Doctor')),
      body: Center(child: Text('Medical Doctor Page')),
    );
  }
}

class MedicalPatientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Medical Patient')),
      body: Center(child: Text('Medical Patient Page')),
    );
  }
}

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      body: Center(child: Text('Help Page')),
    );
  }
}

class ContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contact')),
      body: Center(child: Text('Contact Page')),
    );
  }
}

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

            //I would like to figure out how to change the drawer size
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
              Scaffold.of(context).openDrawer();
              },
            );
          },        
        ),
        toolbarHeight: 140,

        //This is the Yappy Icon
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

        
        //This is the Info button on the right
        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white),
            onPressed: () {
              showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Information'),
              content: const Text('Yappy Terms & Conditions\n''By using Yappy,\n'
                                  'you agree to Use the app responsibly and comply\n'
                                  'with all applicable laws. Respect user privacy\n'
                                  'and refrain from harmful or abusive behavior.\n\n'
                                  'Understand that Yappy is not liable for \n'
                                  'any misuse or legal consequences arising from its use.\n'
                                  'We may update these terms as needed.\n'
                                  'Continued use of Yappy means acceptance of any changes..'),
              actions: [
                TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
                ),
              ],
            );
          },
              );
            },
          ),
        ],
            ),
            // Hamburger Menu (Drawer)
      drawer: Drawer(
        width: 175,
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildDrawerItem('Restaurant', context, RestaurantPage()),
            _buildDrawerItem('Mechanical Aid', context, MechanicalAidPage()),
            _buildDrawerItem('Medical Doctor', context, MedicalDoctorPage()),
            _buildDrawerItem('Medical Patient', context, MedicalPatientPage()),
            _buildDrawerItem('Help', context, HelpPage()),
            _buildDrawerItem('Contact', context, ContactPage()),
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
            _buildButton('Restaurant', context, RestaurantPage()),
            _buildButton('Mechanicial Aid', context, MechanicalAidPage()),
            _buildButton('Medical Doctor', context, MedicalDoctorPage()),
            _buildButton('Medical Patient', context, MedicalPatientPage()),
            _buildButton('Help', context, HelpPage()),
            _buildButton('Contact', context, ContactPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, BuildContext context, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
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

