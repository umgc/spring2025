import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Account'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Version'),
                    content: Text('Version 1.0.0'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('API Keys'),
            onTap: () {
              showDialog(
              context: context,
              builder: (BuildContext context) {
                TextEditingController apiKeyController = TextEditingController();
                return AlertDialog(
                title: Text('Enter API Key'),
                content: TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(hintText: "API Key"),
                ),
                actions: <Widget>[
                  TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  ),
                  TextButton(
                  child: Text('Save'),
                  onPressed: () async {
                    // Saves the API key
                    String apiKey = apiKeyController.text;
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setString('openai_api_key', apiKey);
                    OpenAI.apiKey = apiKey;
                    Navigator.of(context).pop();
                  },
                  ),
                ],
                );
              },
              );
            },
          ),
        ],
      ),
    );
  }
}