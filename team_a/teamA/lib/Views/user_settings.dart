import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:learninglens_app/Api/lms/moodle/moodle_lms_service.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
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
  final TextEditingController _grokKeyController = TextEditingController();
  final TextEditingController _preplexityKeyController = TextEditingController();

  final TextEditingController _googleClientIdController =
      TextEditingController();

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
    final preplexityKey = LocalStorageService.getPerplexityKey();
    final grokKey = LocalStorageService.getGrokKey();
    final googleClientId = LocalStorageService.getGoogleClientId();

    setState(() {
      _usernameController.text = username;
      _passwordController.text = password;
      _moodleUrlController.text = moodleUrl;
      _apiKeyController.text = apiKey;
      _preplexityKeyController.text = preplexityKey;
      _grokKeyController.text = grokKey;
      _googleClientIdController.text = googleClientId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loginNotifier = Provider.of<LoginNotifier>(context);
    final themeColor = Provider.of<ThemeNotifier>(context).primaryColor;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'User Settings',
        onRefresh: () {
          // Add refresh logic here
        },
        userprofileurl: MoodleLmsService().profileImage ?? '',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Moodle Login Block
              _buildMoodleLoginBlock(loginNotifier),

              const SizedBox(height: 20),
              const Divider(),

              // Google Classroom Login Block
              _buildGoogleClassroomLoginBlock(loginNotifier),

              const SizedBox(height: 20),
              const Divider(),

              // API Key Block
              _buildApiKeyBlock(loginNotifier),

              const SizedBox(height: 20),
              const Divider(),

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

  // -------------------------------------------
  // Moodle Login Block
  // -------------------------------------------
  Widget _buildMoodleLoginBlock(LoginNotifier loginNotifier) {
    final moodleState = loginNotifier.moodleState;
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
          enabled: !moodleState.isLoggedIn,
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
          enabled: !moodleState.isLoggedIn,
        ),
        TextField(
          controller: _moodleUrlController,
          decoration: InputDecoration(labelText: 'Moodle URL'),
          enabled: !moodleState.isLoggedIn,
        ),
        const SizedBox(height: 10),
        if (!moodleState.isLoggedIn)
          ElevatedButton(
            onPressed: () {
              loginNotifier.signInWithMoodle(
                _usernameController.text,
                _passwordController.text,
                _moodleUrlController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Login to Moodle'),
          ),
        if (moodleState.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.signOutFromMoodle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout from Moodle'),
          ),
        if (moodleState.errorMessage?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              moodleState.errorMessage!,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------
  // Google Classroom Login Block
  // -------------------------------------------
  Widget _buildGoogleClassroomLoginBlock(LoginNotifier loginNotifier) {
    final googleState = loginNotifier.googleState; // convenience variable

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
        const SizedBox(height: 10),
        if (!googleState.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Login to Google Classroom'),
          ),
        if (googleState.isLoggedIn)
          ElevatedButton(
            onPressed: loginNotifier.signOutFromGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout from Google Classroom'),
          ),
        if (googleState.errorMessage?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              googleState.errorMessage!,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------
  // API Key Block
  // -------------------------------------------
  Widget _buildApiKeyBlock(LoginNotifier loginNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'API Keys:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        _buildApiKeyField(
          label: 'OpenAI API Key',
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
          label: 'Grok AI API Key',
          controller: _grokKeyController,
          loginNotifier: loginNotifier,
          keyType: LLMKey.grok,
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
          obscureText: true,
          decoration: InputDecoration(labelText: label),
          enabled: controller.text.isEmpty, 
          // If you want to disable the TextField once it has a value,
          // keep this. Otherwise, feel free to remove "enabled: controller.text.isEmpty".
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            loginNotifier.saveLLMKey(keyType, controller.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text('Save'),
        ),
        const Divider(),
      ],
    );
  }

  // -------------------------------------------
  // Theme Color Picker
  // -------------------------------------------
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
              pickerColor:
                  Provider.of<ThemeNotifier>(context, listen: false).primaryColor,
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
