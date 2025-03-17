import 'package:flutter/material.dart';
import 'package:yappy/contact_page.dart';
import 'package:yappy/help.dart';
import 'package:yappy/mechanic.dart';
import 'package:yappy/medical_doctor.dart';
import 'package:yappy/medical_patient.dart';
import 'package:yappy/restaurant.dart';
import 'package:yappy/tool_bar.dart';
import 'package:yappy/settings_page.dart';
import 'package:yappy/tutorialPage.dart';
import './services/model_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ModelManager _modelManager = ModelManager();
  
  
  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      final shouldShowDialog = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Welcome!'),
          content: const Text('Is this your first time using the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (shouldShowDialog != null && shouldShowDialog) {
        await prefs.setBool('isFirstTime', false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TutorialPage()),
          );
        }
      }
    }
  }

    Future<void> _checkModelsExist() async {
    try {
      // Skip check if downloads are already in progress
      if (_modelManager.isDownloadInProgress()) {
        return;
      }
      
      final modelsExist = await _modelManager.modelsExist();
      if (!modelsExist && mounted) {
        // Models don't exist, prompt for download
        final shouldDownload = await _modelManager.showDownloadDialog(context);
        if (shouldDownload && mounted) {
          await _modelManager.downloadModels(context);
        }
      }
    } catch (e) {
      debugPrint('Error checking models: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if models exist after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkModelsExist();
      _checkFirstTimeUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(140),
        child: ToolBar(showHamburger: false), // Using the ToolBar widget
      ),
      body: Column(
        children: [
          _buildButton('Restaurant', context, RestaurantPage()),
          _buildButton('Vehicle Maintenance', context, MechanicalAidPage()),
          _buildButton('Medical Doctor', context, MedicalDoctorPage()),
          _buildButton('Medical Patient', context, MedicalPatientPage()),
          _buildButton('Help', context, HelpPage()),
          _buildButton('Contact', context, ContactPage()),
          _buildButton('Settings', context, SettingsPage()),
        ],
      ),
    );
  }

  // Function for button navigation
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
}