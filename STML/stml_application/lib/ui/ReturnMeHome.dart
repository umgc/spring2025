import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Dodger Stadium in Los Angeles
const double dummyLat = 34.073851;
const double dummyLng = -118.240967;

/// Pulls from the .env file
final String googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

class ReturnMeHomePage extends StatefulWidget {
  const ReturnMeHomePage({Key? key}) : super(key: key);

  @override
  _ReturnMeHomePageState createState() => _ReturnMeHomePageState();
}

class _ReturnMeHomePageState extends State<ReturnMeHomePage> {
  List<DirectionStep> _steps = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Position? _currentPosition;

  /// Which step is currently displayed
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  Future<void> _fetchDirections() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // 1. Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permissions are denied';
      }

      // 2. Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      final origin = '${position.latitude},${position.longitude}';
      final destination = '$dummyLat,$dummyLng';

      // 3. Fetch directions from your server
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/directions?origin=$origin&destination=$destination');

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final stepsJson = data['routes'][0]['legs'][0]['steps'] as List;

          // Parse each step's instruction + distance into our DirectionStep objects
          final parsedSteps = stepsJson.map((stepData) {
            final htmlInstructions = stepData['html_instructions'] as String;
            final instruction = _removeHtmlTags(htmlInstructions);

            // Extract the distance text (e.g. "0.3 mi" or "500 m")
            // from stepData['distance']['text']
            final distanceText = stepData['distance']['text'] as String;

            // Identify arrow direction
            final arrow = _deriveArrow(instruction);

            return DirectionStep(
              instruction: instruction,
              arrow: arrow,
              distance: distanceText,
            );
          }).toList();

          setState(() {
            _steps = parsedSteps;
            _isLoading = false;
            _currentStepIndex = 0; // start at the first step
          });
        } else {
          throw 'Directions API error: ${data['status']}';
        }
      } else {
        throw 'HTTP error: ${response.statusCode}';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching directions: $e';
        _isLoading = false;
      });
    }
  }

  /// Remove simple HTML tags
  String _removeHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '') // remove all HTML tags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }

  /// Determine arrow direction
  DirectionArrow _deriveArrow(String instruction) {
    final lowered = instruction.toLowerCase();
    if (lowered.contains('left')) {
      return DirectionArrow.left;
    } else if (lowered.contains('right')) {
      return DirectionArrow.right;
    } else {
      return DirectionArrow.forward;
    }
  }

  String getBaseUrl() {
    if (kIsWeb) {
      // Running in a browser
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      // Android emulator
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      // iOS simulator
      return "http://localhost:3000";
    } else {
      // Windows, macOS, Linux desktop, etc.
      return "http://localhost:3000";
    }
  }

  /// Go to next direction step
  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If loading or error, show a simple message
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: Center(child: Text(_errorMessage)),
      );
    }

    // If we have no steps, display a placeholder
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: const Center(child: Text('No directions found')),
      );
    }

    // Show the current step
    final currentStep = _steps[_currentStepIndex];
    final arrowIcon = _getArrowIcon(currentStep.arrow);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Me Home'),
      ),
      body: Center(
        child: Column(
          // Center everything vertically and horizontally
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_currentPosition != null)
              Text(
                'Current Location:\n'
                    'Latitude: ${_currentPosition!.latitude}\n'
                    'Longitude: ${_currentPosition!.longitude}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 40),
            // BIG Arrow Icon
            Icon(
              arrowIcon,
              size: 100,
            ),
            const SizedBox(height: 20),
            // Combine instruction + distance in the displayed text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${currentStep.instruction}\n'
                    '(Walk ${currentStep.distance})', // add the distance here
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            // Next Step Button
            ElevatedButton(
              onPressed: _currentStepIndex < _steps.length - 1
                  ? _goToNextStep
                  : null, // disable if at last step
              child: const Text('Next Step'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getArrowIcon(DirectionArrow arrow) {
    switch (arrow) {
      case DirectionArrow.left:
        return Icons.arrow_left;
      case DirectionArrow.right:
        return Icons.arrow_right;
      case DirectionArrow.forward:
      default:
        return Icons.arrow_upward;
    }
  }
}

/// Represents the direction: left, right, forward
enum DirectionArrow { left, right, forward }

/// Represents a single step in your direction instructions
class DirectionStep {
  final String instruction;
  final DirectionArrow arrow;

  ///The distance for each step
  final String distance;

  DirectionStep({
    required this.instruction,
    required this.arrow,
    required this.distance,
  });
}
