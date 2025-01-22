import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:learninglens_app/Controller/custom_appbar.dart';
import 'package:provider/provider.dart';


class UserSettings extends StatefulWidget {
  @override
  UserSettingsState createState() => UserSettingsState();
}

class UserSettingsState extends State<UserSettings> {
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
              pickerColor: Provider.of<ThemeNotifier>(context, listen: false).primaryColor,
              onColorChanged: (color) {
                Provider.of<ThemeNotifier>(context, listen: false).updateTheme(color); // Update global theme
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
              Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = Provider.of<ThemeNotifier>(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
        backgroundColor: themeColor,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickColor,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text('Pick Theme Color'),
        ),
      ),
    );
  }
}
