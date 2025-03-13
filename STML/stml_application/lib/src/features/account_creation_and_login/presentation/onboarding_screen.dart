import 'package:flutter/material.dart';
import 'package:memoryminder/src/features/account_creation_and_login/presentation/registration_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<Map<String, dynamic>> stmlUsers = [];

  void _addUser() {
    setState(() {
      stmlUsers.add({
        'firstName': TextEditingController(),
        'lastName': TextEditingController(),
        'location': TextEditingController(),
        'age': TextEditingController(),
        'emergencyContacts': [TextEditingController()],
      });
    });
  }

  void _addEmergencyContact(int index) {
    setState(() {
      stmlUsers[index]['emergencyContacts'].add(TextEditingController());
    });
  }

  void _removeUser(int index) {
    setState(() {
      stmlUsers.removeAt(index);
    });
  }

  void _submitData() {
    for (var user in stmlUsers) {
      print("STML User: ${user['firstName'].text} ${user['lastName'].text}");
      print("Location: ${user['location'].text}");
      print("Age: ${user['age'].text}");
      print("Emergency Contacts:");
      for (var contact in user['emergencyContacts']) {
        print(" - ${contact.text}");
      }
      print("-------------------------");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("STML Users data submitted!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Onboarding - STML Users")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: stmlUsers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("STML User ${index + 1}",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          TextField(
                            controller: stmlUsers[index]['firstName'],
                            decoration:
                                InputDecoration(labelText: "First Name"),
                          ),
                          TextField(
                            controller: stmlUsers[index]['lastName'],
                            decoration: InputDecoration(labelText: "Last Name"),
                          ),
                          TextField(
                            controller: stmlUsers[index]['location'],
                            decoration: InputDecoration(labelText: "Location"),
                          ),
                          TextField(
                            controller: stmlUsers[index]['age'],
                            decoration: InputDecoration(labelText: "Age"),
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(height: 10),
                          Text("Emergency Contacts",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          ...List.generate(
                            stmlUsers[index]['emergencyContacts'].length,
                            (contactIndex) => Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: stmlUsers[index]
                                        ['emergencyContacts'][contactIndex],
                                    decoration: InputDecoration(
                                        labelText:
                                            "Emergency Contact ${contactIndex + 1}"),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      stmlUsers[index]['emergencyContacts']
                                          .removeAt(contactIndex);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.add),
                            label: Text("Add Emergency Contact"),
                            onPressed: () => _addEmergencyContact(index),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text("Remove User"),
                            onPressed: () => _removeUser(index),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text("Add STML User"),
              onPressed: _addUser,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitData,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
