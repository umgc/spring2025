// lib/services/esri_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class EsriClient {
  final String apiKey;
  final Logger _logger = Logger('EsriClient');
  static const String _baseUrl =
      'https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World';

  EsriClient({required this.apiKey});

  Future<Map<String, dynamic>> getRouteToHome(String currentLocation) async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/solve'), body: {
        'f': 'json',
        'token': apiKey,
        'stops': jsonEncode({
          'type': 'features',
          'features': [
            {
              'geometry': {'x': 0, 'y': 0}
            }, // Current location (à remplacer)
            {
              'geometry': {'x': 1, 'y': 1}
            } // Home location (à configurer)
          ]
        }),
        'returnDirections': 'true'
      });

      return _handleResponse(response);
    } catch (e, stackTrace) {
      _logger.severe('Failed to get route', e, stackTrace);
      rethrow;
    }
  }

  Future<void> sendDirectionsToCaregiver(Map<String, dynamic> route) async {
    try {
      // Implémentation de l'envoi des directions via l'API ESRI
      final response = await http.post(Uri.parse('$_baseUrl/sendDirections'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(
              {'route': route, 'apiKey': apiKey, 'format': 'MOBILE'}));

      _handleResponse(response);
    } catch (e, stackTrace) {
      _logger.severe('Failed to send directions', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      _logger
          .severe('ESRI API Error: ${response.statusCode} - ${response.body}');
      throw Exception('ESRI API request failed: ${response.reasonPhrase}');
    }
  }

  // Pour la géocodification inverse (section 2.1.1 du TDD)
  Future<String> reverseGeocode(double lat, double lon) async {
    final response = await http.get(Uri.parse(
        'https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode'
        '?location=${lon.toStringAsFixed(6)},${lat.toStringAsFixed(6)}'
        '&f=json'
        '&token=$apiKey'));

    final data = _handleResponse(response);
    return data['address']['Match_addr'] ?? 'Unknown location';
  }
}
