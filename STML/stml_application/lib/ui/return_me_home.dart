import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Destination: Dodger Stadium
const double dummyLat = 34.073851;
const double dummyLng = -118.240967;

/// Optional: reading from .env (in case you need the key in-app)
final String googleApiKey = dotenv.env['GOOGLE_API_KEY'] ?? '';

class ReturnMeHomePage extends StatefulWidget {
  const ReturnMeHomePage({Key? key}) : super(key: key);

  @override
  _ReturnMeHomePageState createState() => _ReturnMeHomePageState();
}

class _ReturnMeHomePageState extends State<ReturnMeHomePage> {
  /// Steps from the Directions API
  List<DirectionStep> _steps = [];

  /// Track loading/error states
  bool _isLoading = false;
  String _errorMessage = '';

  /// Current user position
  Position? _currentPosition;

  /// Index of the currently displayed step
  int _currentStepIndex = 0;

  /// Subscription for continuous location updates
  late StreamSubscription<Position> _positionSubscription;

  @override
  void initState() {
    super.initState();

    // 1) First handle permission once
    _handlePermission().then((_) {
      // If permission was granted, start streaming location updates
      _startLocationStream();
    });
  }

  /// Request location permission at the start
  Future<void> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage = 'Location permissions are denied';
      });
    }
  }

  /// Subscribe to continuous location updates
  void _startLocationStream() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((Position position) {
      // Each time location changes, fetch directions again
      _updateDirections(position);
    });
  }

  /// Called whenever we get a new Position
  Future<void> _updateDirections(Position newPosition) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Save the new position
      _currentPosition = newPosition;

      final origin = '${newPosition.latitude},${newPosition.longitude}';
      final destination = '$dummyLat,$dummyLng';

      // Build the URL to our Node proxy
      final baseUrl = getBaseUrl();
      final url = Uri.parse('$baseUrl/directions?origin=$origin&destination=$destination');

      // Fetch directions
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final stepsJson = data['routes'][0]['legs'][0]['steps'] as List;

          // Parse each step
          final parsedSteps = stepsJson.map((stepData) {
            final htmlInstructions = stepData['html_instructions'] as String;
            final instruction = _removeHtmlTags(htmlInstructions);

            final distanceText = stepData['distance']['text'] as String;

            // Determine arrow direction
            final arrow = _deriveArrow(instruction);

            return DirectionStep(
              instruction: instruction,
              arrow: arrow,
              distance: distanceText,
            );
          }).toList();

          setState(() {
            _steps = parsedSteps;
            _currentStepIndex = 0; // reset to the first step
            _isLoading = false;
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

  @override
  void dispose() {
    // Cancel subscription to avoid memory leaks
    _positionSubscription.cancel();
    super.dispose();
  }

  /// Remove simple HTML tags in instructions
  String _removeHtmlTags(String htmlString) {
    return htmlString
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');
  }

  /// Determine arrow direction from the instruction text
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

  /// Construct the base URL to our Node server
  String getBaseUrl() {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  /// Manual “Next Step” progression if you want
  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If we have an error or are loading, show appropriate UI
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: Center(child: Text(_errorMessage)),
      );
    }

    if (_isLoading && _steps.isEmpty) {
      // Show a loading spinner on initial load
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If steps are not yet loaded or we had an error
    if (_steps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return Me Home')),
        body: const Center(child: Text('No directions found')),
      );
    }

    // We have steps: show the current step
    final currentStep = _steps[_currentStepIndex];
    final arrowIcon = _getArrowIcon(currentStep.arrow);

    return Scaffold(
      appBar: AppBar(title: const Text('Return Me Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_currentPosition != null)
              Text(
                'Destination: Dodger Stadium, Los Angeles, CA\n'
                    'Current Loc: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 40),
            // Show arrow
            Icon(arrowIcon, size: 100),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${currentStep.instruction}\n(Walk ${currentStep.distance})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _currentStepIndex < _steps.length - 1
                  ? _goToNextStep
                  : null,
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

/// Enum for direction arrows
enum DirectionArrow { left, right, forward }

/// Data class for each step
class DirectionStep {
  final String instruction;
  final DirectionArrow arrow;
  final String distance;

  DirectionStep({
    required this.instruction,
    required this.arrow,
    required this.distance,
  });
}
