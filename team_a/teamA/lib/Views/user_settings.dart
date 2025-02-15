import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/notifiers/theme_notifier.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';

class UserSettings extends StatefulWidget {
  @override
  UserSettingsState createState() => UserSettingsState();
}

class UserSettingsState extends State<UserSettings> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _moodleUrlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _claudeKeyController = TextEditingController();
  final TextEditingController _preplexityKeyController = TextEditingController();

  final LocalStorageService _localStorage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final username = await _localStorage.getUsername() ?? '';
    final password = await _localStorage.getPassword() ?? '';
    final moodleUrl = await _localStorage.getMoodleUrl() ?? '';
    final apiKey = await _localStorage.getOpenAIKey() ?? '';
    final claudeKey = await _localStorage.getClaudeKey() ?? '';
    final preplexityKey = await _localStorage.getPreplexityKey() ?? '';

    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _moodleUrlController.text = moodleUrl;
      _apiKeyController.text = apiKey;
      _claudeKeyController.text = claudeKey;
      _preplexityKeyController.text = preplexityKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginNotifier =
        Provider.of<LoginNotifier>(context); // Use provider for login state
    Color themeColor = Provider.of<ThemeNotifier>(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: themeColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Label saying Moodle API Login:
            Text(
              'Moodle API Login:',
              style: TextStyle(fontSize: 20),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
              enabled: !loginNotifier.isLoggedIn,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              enabled: !loginNotifier.isLoggedIn,
            ),
            TextField(
              controller: _moodleUrlController,
              decoration: InputDecoration(labelText: 'Moodle URL'),
              // disabled text field if logged in
              enabled: !loginNotifier.isLoggedIn,
            ),
            SizedBox(height: 20),

            // Show login button if NOT logged in
            if (!loginNotifier.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  loginNotifier.login(
                    _usernameController.text,
                    _passwordController.text,
                    _moodleUrlController.text,
                  );
                },
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            // Show logout button if logged in
            if (loginNotifier.isLoggedIn)
              ElevatedButton(
                onPressed: loginNotifier.logout,
                child: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),

            SizedBox(height: 20),
            Divider(),

            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(labelText: 'Open AI API Key'),
              enabled: !loginNotifier.isLoggedIn,
            ),
            SizedBox(height: 20),

            // Show login button if NOT logged in
            if (!loginNotifier.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  // pop up a dialog to confirm the user wants to save the API key
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Save API Key?'),
                        content:
                            Text('Are you sure you want to save this API key?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // set the key local storages
                              loginNotifier.saveLLMKey(LLMKey.openAI, _apiKeyController.text);
                              Navigator.of(context).pop();
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            Divider(),

            TextField(
              controller: _preplexityKeyController,
              decoration: InputDecoration(labelText: 'Preplexity AI API Key'),
              enabled: !loginNotifier.isLoggedIn,
            ),
            SizedBox(height: 20),

            // Show login button if NOT logged in
            if (!loginNotifier.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  // pop up a dialog to confirm the user wants to save the API key
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Save API Key?'),
                        content:
                            Text('Are you sure you want to save this API key?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // set the key local storages
                              loginNotifier.saveLLMKey(LLMKey.perplexity, _preplexityKeyController.text);
                              Navigator.of(context).pop();
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            Divider(),
            TextField(
              controller: _claudeKeyController,
              decoration: InputDecoration(labelText: 'Claude AI API Key'),
              enabled: !loginNotifier.isLoggedIn,
            ),
            SizedBox(height: 20),

            // Show login button if NOT logged in
            if (!loginNotifier.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  // pop up a dialog to confirm the user wants to save the API key
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Save API Key?'),
                        content:
                            Text('Are you sure you want to save this API key?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              // set the key local storages
                              loginNotifier.saveLLMKey(LLMKey.claude, _claudeKeyController.text);
                              Navigator.of(context).pop();
                            },
                            child: Text('Save'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            Divider(),

            // loop through a list of enumerated keys and values to display the key and value in a text field
            // make this flexible to support adding new llms
            // Divider(),

            // Label saying Theme Color Picker:
            Text(
              'Theme Color Picker:',
              style: TextStyle(fontSize: 20),
            ),
            ElevatedButton(
              onPressed: _pickColor,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text('Pick Theme Color'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pick a theme color',
          style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 300,
            height: 50,
            child: BlockPicker(
              pickerColor: Provider.of<ThemeNotifier>(context, listen: false)
                  .primaryColor,
              onColorChanged: (color) {
                Provider.of<ThemeNotifier>(context, listen: false)
                    .updateTheme(color);
              },
              availableColors: [
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Select'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
