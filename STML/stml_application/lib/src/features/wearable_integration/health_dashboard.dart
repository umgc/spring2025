import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fitbitter/fitbitter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class HealthDashboard extends StatefulWidget {
  final FitbitCredentials fitbitCredentials;
  const HealthDashboard({super.key, required this.fitbitCredentials});

  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final storage = FlutterSecureStorage();
  String bpm = "0";
  String heartRate = "0";
  String steps = "0";
  String sleep = "0";
  List<FlSpot> heartRateGraphData = [];

  @override
  void initState() {
    super.initState();
    fetchFitbitData();
  }

  Future<void> fetchFitbitData() async {
    String? accessToken = await storage.read(key: 'fitbitAccessToken');

    try {
      // Fetch Heart Rate
      final heartRateResponse = await http.get(
        Uri.parse('https://api.fitbit.com/1/user/-/activities/heart/date/today/1d.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      final heartRateData = jsonDecode(heartRateResponse.body);
      print('Heart Rate Data: $heartRateData');

      // Extract Resting Heart Rate
      var restingHeartRate = heartRateData['activities-heart'][0]['value']['restingHeartRate'] ?? 0;

      if (heartRateData.containsKey('activities-heart-intraday') &&
        heartRateData['activities-heart-intraday'].containsKey('dataset')) {
        List<dynamic> timeSeriesData = heartRateData['activities-heart-intraday']['dataset'];
        List<FlSpot> graphData = [];
        for (var dataPoint in timeSeriesData) {
          double time = _convertTimeToHour(dataPoint['time']); // Convert "hh:mm:ss" to double
          double bpm = (dataPoint['value'] as num).toDouble();
          graphData.add(FlSpot(time, bpm));
        }

        if (mounted) {
          setState(() {
            heartRateGraphData = graphData; // Now the graph gets updated properly!
        });
  }
      } else {
        print("No intraday heart rate data found.");
        if (mounted) {
          setState(() {
            heartRateGraphData = [];
          });
        }
      }

      // Fetch Steps Data
      final stepsResponse = await http.get(
        Uri.parse('https://api.fitbit.com/1/user/-/activities/steps/date/today/1d.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      final stepsData = jsonDecode(stepsResponse.body);
      print('Steps Data: $stepsData');
      var totalSteps = stepsData['activities-steps'][0]['value'] ?? 0;

      // Fetch Sleep Data
      final sleepResponse = await http.get(
        Uri.parse('https://api.fitbit.com/1.2/user/-/sleep/date/today.json'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
      final sleepData = jsonDecode(sleepResponse.body);
      print('Sleep Data: $sleepData');

      // Extract Sleep Minutes
      var totalSleepMinutes = sleepData['summary']['totalMinutesAsleep'] ?? 0;

      // Update UI State
      if (mounted) {
        setState(() {
          heartRate = restingHeartRate.toString(); // Heart Rate
          steps = totalSteps.toString(); // Steps
          sleep = totalSleepMinutes.toString(); // Sleep Minutes
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          heartRate = "Error fetching data";
          steps = "Error fetching data";
          sleep = "Error fetching data";
          heartRateGraphData = [];
        });
      }
      print("Fitbit Data Fetching Error: $e");
    }
  }

  // Convert "hh:mm:ss" to a double representing hours (e.g., "12:30:00" -> 12.5)
  double _convertTimeToHour(String time) {
    List<String> parts = time.split(":");
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours + (minutes / 60.0);
  }

  Future<void> logOut(BuildContext context) async {
    try {
      // Retrieve the stored access token
      String? accessToken = await storage.read(key: 'fitbitAccessToken');

      // Make a request to revoke Fitbit access
      final response = await http.post(
        Uri.parse('https://api.fitbit.com/oauth2/revoke'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('23Q4PQ:ab22db61074912d2e4090298f88c8c82'))}', // Client ID and Secret Base64 encoded
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'token': accessToken,
        },
      );

      if (response.statusCode == 200) {
        print("Successfully revoked Fitbit access");
      } else {
        print("Fitbit Revoke Failed: ${response.body}");
      }
    
      // Clear tokens from storage
      await storage.delete(key: 'fitbitAccessToken');
      await storage.delete(key: 'fitbitRefreshToken');

      // Navigate back to the Welcome/Login Page
      // Navigator.of(context).pushReplacement(MaterialPageRoute(
      //   builder: (context) => HomeScreen(),
      // ));
      Navigator.pushReplacementNamed(context, '/homeScreen');

      print("Successfully logged out");
    } catch (e) {
      print("Logout Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Health Metrics"),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: Colors.red),
          onPressed: () => logOut(context),
        ),
      ],),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Text("Health Metrics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Health Metrics',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMetricTile("Heart Rate", heartRate),
                  _buildMetricTile("Steps", steps),
                  _buildMetricTile("Sleep (min)", sleep),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: fetchFitbitData,
                child: Text("🔄 Refresh Data"),
              ),
              SizedBox(height: 30),
                // Text("Heart Rate Over 24 Hours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Heart Rate Over 24 Hours',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                _buildHeartRateGraph(), // Display the graph
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value) {
    return Expanded(  // Ensure all tiles take equal width
      child: Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Build Heart Rate Graph
  Widget _buildHeartRateGraph() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}h', style: TextStyle(fontSize: 12));
                },
                reservedSize: 22,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: heartRateGraphData, // Use fetched heart rate data
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
