import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './services/model_manager.dart';
import './main.dart';
import 'package:yappy/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _modelsDownloaded = false;
  bool _wifiOnlyDownloads = true;
  bool _isLoading = true;
  final ModelManager _modelManager = ModelManager();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Check models status
      final exist = await _modelManager.modelsExist();
      
      // Load Wi-Fi only setting
      final prefs = await SharedPreferences.getInstance();
      final wifiOnly = prefs.getBool('wifi_only_downloads') ?? true;
      
      if (mounted) {
        setState(() {
          _modelsDownloaded = exist;
          _wifiOnlyDownloads = wifiOnly;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: <Widget>[
          // Original settings items
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('About Yappy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Version'),
                    content: const Text('Version 1.0.0'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('OpenAI API Key'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController apiKeyController = TextEditingController();
                  return AlertDialog(
                    title: const Text('Enter OpenAI API Key'),
                    content: TextField(
                      controller: apiKeyController,
                      decoration: const InputDecoration(hintText: "API Key"),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Save'),
                        onPressed: () async {
                          // Save the API key
                          String apiKey = apiKeyController.text;
                          await preferences.setString('openai_api_key', apiKey);
                          OpenAI.apiKey = apiKey;
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle Dark Mode on or off'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('AWS Credentials'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController accessKeyController = TextEditingController();
                  TextEditingController secretKeyController = TextEditingController();
                  TextEditingController regionController = TextEditingController();
                  
                  return AlertDialog(
                    title: const Text('Enter AWS Credentials'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: accessKeyController,
                            decoration: const InputDecoration(
                              hintText: "AWS Access Key",
                              labelText: "Access Key",
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: secretKeyController,
                            decoration: const InputDecoration(
                              hintText: "AWS Secret Key",
                              labelText: "Secret Key",
                            ),
                            obscureText: true, // Hide sensitive information
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: regionController,
                            decoration: const InputDecoration(
                              hintText: "AWS Region (e.g., us-east-1)",
                              labelText: "Region",
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Save'),
                        onPressed: () async {
                          // Save all AWS credentials
                          String accessKey = accessKeyController.text;
                          String secretKey = secretKeyController.text;
                          String region = regionController.text;
                          
                          await preferences.setString('aws_access_key', accessKey);
                          await preferences.setString('aws_secret_key', secretKey);
                          await preferences.setString('aws_region', region);
                          await preferences.setBool('awsAvailable', true);
                                                    
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const Divider(),
          
          // Model management settings
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'AI Speech Models',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Speech Recognition Models'),
            subtitle: Text(_modelsDownloaded 
                ? 'Downloaded and ready to use' 
                : 'Not downloaded'),
            trailing: _modelsDownloaded
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    onPressed: () => _handleModelDownload(context),
                    child: const Text('Download'),
                  ),
          ),
          
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Download on Wi-Fi only'),
            subtitle: const Text(
                'When enabled, models will only download when connected to Wi-Fi'),
            value: _wifiOnlyDownloads,
            onChanged: (value) async {
              setState(() {
                _wifiOnlyDownloads = value;
              });
              // Save preference to shared preferences
              await _modelManager.saveWifiOnlySetting(value);
            },
          ),
          
          if (_modelsDownloaded)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete Models'),
              subtitle: const Text('Free up space by removing downloaded models'),
              onTap: () => _handleDeleteModels(context),
            ),
        ],
      ),
    );
  }

  Future<void> _handleModelDownload(BuildContext context) async {
    await _modelManager.downloadModelsFromSettings(context);
    
    if (!mounted) return;
    
    // Refresh the model status
    final exist = await _modelManager.modelsExist();
    
    if (!mounted) return;
    
    setState(() {
      _modelsDownloaded = exist;
    });
  }

  Future<void> _handleDeleteModels(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Models?'),
        content: const Text(
          'This will delete all downloaded speech models. '
          'You will need to download them again to use the app\'s '
          'speech recognition features.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!shouldDelete || !mounted) return;
    
    final success = await _modelManager.deleteModels();
    
    if (!mounted) return;
    
    setState(() {
      _modelsDownloaded = !success;
    });
    
    _showResultSnackBar(success);
  }
  
  // Separate method for showing the snackbar to avoid context across async gap
  void _showResultSnackBar(bool success) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Models deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete models'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

}