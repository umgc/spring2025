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
    final loginNotifier = Provider.of<LoginNotifier>(context);
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
              enabled: !loginNotifier.isLoggedIn,
            ),
            SizedBox(height: 20),

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

            _buildApiKeyField(
                label: 'Open AI API Key',
                controller: _apiKeyController,
                loginNotifier: loginNotifier,
                keyType: LLMKey.openAI),

            _buildApiKeyField(
                label: 'Preplexity AI API Key',
                controller: _preplexityKeyController,
                loginNotifier: loginNotifier,
                keyType: LLMKey.perplexity),

            _buildApiKeyField(
                label: 'Claude AI API Key',
                controller: _claudeKeyController,
                loginNotifier: loginNotifier,
                keyType: LLMKey.claude),

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

  Widget _buildApiKeyField({
    required String label,
    required TextEditingController controller,
    required LoginNotifier loginNotifier,
    required LLMKey keyType,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
        ),
        SizedBox(height: 10),
        ElevatedButton(
            onPressed: () {
              loginNotifier.saveLLMKey(keyType, controller.text);
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        Divider(),
      ],
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
