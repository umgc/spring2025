import 'package:flutter/material.dart';
import 'package:fitbitter/fitbitter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const storage = FlutterSecureStorage();

class FitbitLoginPage extends StatelessWidget {

  const FitbitLoginPage({super.key}); // Securely store access tokens

  Future<void> connectToFitbit(BuildContext context) async {
    try {
      FitbitCredentials? fitbitCredentials = await FitbitConnector.authorize(
        clientID: dotenv.env['FITBIT_CLIENT_ID']!,
        clientSecret: dotenv.env['FITBIT_CLIENT_SECRET']!,
        redirectUri: 'stmlapp://aadil',
        callbackUrlScheme: 'stmlapp',
      );

      // Get access token
      // await storage.write(key: 'fitbitAccessToken', value: fitbitCredentials?.fitbitAccessToken);
      if (!context.mounted) return; // Ensure context is still valid

      if (fitbitCredentials != null) {
        // ✅ Store all necessary credentials
        await storage.write(key: 'fitbitAccessToken', value: fitbitCredentials.fitbitAccessToken);
        await storage.write(key: 'fitbitRefreshToken', value: fitbitCredentials.fitbitRefreshToken);
        await storage.write(key: 'fitbitUserId', value: fitbitCredentials.userID);
        print('Fitbit Authentication Successful! Token saved.');

        // Navigate to the health metrics dashboard
        Navigator.pushReplacementNamed(context, '/healthMetrics');
      }

    } catch (e) {
      print('Fitbit Authentication Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 2, 63, 129),
        elevation: 0.0,
        centerTitle: true,
        title: const Text(
          "Connect to Fitbit",
          textAlign: TextAlign.center,
          style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Montserrat')
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/fitbit_logo.jpg',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                'Connect to Sync Health Data',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => connectToFitbit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Connect Now',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
