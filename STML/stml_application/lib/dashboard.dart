import 'safe_zone_service.dart'; // Import the SafeZoneService file
import 'safe_zone.dart'; // Import the SafeZone model

import 'package:flutter/material.dart';

class CaregiverDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Caregiver Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns in grid
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: 4, // Adjust the number of features
          itemBuilder: (context, index) {
            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  // Add your navigation functionality here
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Feature $index', // Replace with actual feature name
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
