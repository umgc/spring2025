import 'package:flutter/material.dart';
import './services/model_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            leading: const Icon(Icons.account_circle),
            title: const Text('Account'),
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
            leading: const Icon(Icons.key),
            title: const Text('API Keys'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController apiKeyController = TextEditingController();
                  return AlertDialog(
                    title: const Text('Enter API Key'),
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
                        onPressed: () {
                          // Save the API key to env.dart file
                          // String apiKey = apiKeyController.text;
                          // Add your logic to save the API key here
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          // Divider to separate original and new settings
          const Divider(),
          
          // New model management settings
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
    final result = await _modelManager.downloadModelsFromSettings(context);
    
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