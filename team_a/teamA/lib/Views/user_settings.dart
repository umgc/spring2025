import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:learninglens_app/Api/moodle_api_singleton.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:learninglens_app/Controller/main_controller.dart';
import 'package:learninglens_app/Views/dashboard.dart';
import 'package:learninglens_app/Views/g_courses.dart';
import 'package:learninglens_app/Views/g_dashboard.dart';
import 'package:learninglens_app/notifiers/login_notifier.dart';
import 'package:learninglens_app/notifiers/theme_notifier.dart';
import 'package:learninglens_app/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final TextEditingController _preplexityKeyController =
      TextEditingController();
  // Add Google Classroom Client ID controller
  final TextEditingController _googleClientIdController =
      TextEditingController();
  //
  bool _isLoading = false;
  final MainController _controller = MainController();

  @override
  void initState() {
    super.initState();
    _loadStoredValues();
  }

  Future<void> _loadStoredValues() async {
    final username = LocalStorageService.getUsername();
    final password = LocalStorageService.getPassword();
    final moodleUrl = LocalStorageService.getMoodleUrl();
    final apiKey = LocalStorageService.getOpenAIKey();
    final claudeKey = LocalStorageService.getClaudeKey();
    final preplexityKey = LocalStorageService.getPerplexityKey();
    // Load Google Client ID from .env file
    final googleClientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';

    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _moodleUrlController.text = moodleUrl;
      _apiKeyController.text = apiKey;
      _claudeKeyController.text = claudeKey;
      _preplexityKeyController.text = preplexityKey;
      _googleClientIdController.text = googleClientId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LoginNotifier>(context);
    Color themeColor = Provider.of<ThemeNotifier>(context).primaryColor;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'User Settings',
      //     style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
      //   ),
      //   backgroundColor: themeColor,
      // ),
      appBar: CustomAppBar(
          title: 'User Settings',
          userprofileurl: MoodleApiSingleton().moodleProfileImage ?? ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Moodle Login Block
              _buildMoodleLoginBlock(loginNotifier),

              SizedBox(height: 20),
              Divider(),

              // Google Classroom Login Block
              _buildGoogleClassroomLoginBlock(loginNotifier),

              SizedBox(height: 20),
              Divider(),

              // API Key Block
              _buildApiKeyBlock(loginNotifier),

              SizedBox(height: 20),
              Divider(),

              // Theme Color Picker
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
      ),
    );
  }

  // Moodle Login Block
  Widget _buildMoodleLoginBlock(LoginNotifier loginNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Moodle Login:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        SizedBox(height: 10),
        if (!loginNotifier.isLoggedIn)
          ElevatedButton(
            onPressed: () {
              loginNotifier.login(
                _usernameController.text,
                _passwordController.text,
                _moodleUrlController.text,
              );
            },
            child: Text('Login to Moodle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        if (loginNotifier.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.logout,
            child: Text('Logout from Moodle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  // Google Classroom Login Block
  Widget _buildGoogleClassroomLoginBlock(LoginNotifier loginNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Google Classroom Login:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: _googleClientIdController,
          decoration: InputDecoration(labelText: 'Client ID'),
          enabled: false, // Make it non-editable
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _handleSignIn();
          },
          child: Text('Login to Google Classroom'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.signInWithGoogle(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GoogleTeacherDashboard()),
      );
    } catch (error) {
      print("Google Sign-In Error: $error");
      _showLoginFailedDialog("Google Sign-In failed: $error");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLoginFailedDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login Failed"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // API Key Block
  Widget _buildApiKeyBlock(LoginNotifier loginNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Keys:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        _buildApiKeyField(
          label: 'Open AI API Key',
          controller: _apiKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.openAI,
        ),
        _buildApiKeyField(
          label: 'Preplexity AI API Key',
          controller: _preplexityKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.perplexity,
        ),
        _buildApiKeyField(
          label: 'Claude AI API Key',
          controller: _claudeKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.claude,
        ),
      ],
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
          enabled: controller
              .text.isEmpty, // Make it non-editable if a key is present
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
