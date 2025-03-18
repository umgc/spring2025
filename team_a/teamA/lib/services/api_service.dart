import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class ApiService {
  // Create a single Logger instance to reuse.
  // We read the 'LOGGING_ENABLED' environment variable as a string,
  // compare it to 'true', and then decide the log level.
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of stacktrace methods to show
      errorMethodCount: 5, // Number of stacktrace methods for errors
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    // if we ever want to turn this logging off, we can use the following:
    // level: dotenv.env['LOGGING_ENABLED'] == 'true'
    //     ? Level.verbose
    //     : Level.nothing,
  );

  /// Sends an HTTP POST request to the specified [url].
  ///
  /// Optional parameters:
  /// - [headers] for custom headers
  /// - [body] for post data
  /// - [encoding] to specify the encoding for the request
  ///
  /// Returns the [http.Response] from the server.
  Future<http.Response> httpPost(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
        encoding: encoding,
      );
      stopwatch.stop();
      _handleResponse(response, method: 'POST', duration: stopwatch.elapsed);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.e(
        'Exception (POST) -> $url (${stopwatch.elapsedMilliseconds}ms)',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Sends an HTTP GET request to the specified [url].
  ///
  /// Optional parameters:
  /// - [headers] for custom headers
  ///
  /// Returns the [http.Response] from the server.
  Future<http.Response> httpGet(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(url, headers: headers);
      stopwatch.stop();

      _handleResponse(response, method: 'GET', duration: stopwatch.elapsed);
      return response;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.e(
        'Exception (GET) -> $url (${stopwatch.elapsedMilliseconds}ms)',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handles the [response], logging success or error messages.
  /// Includes [method] (GET/POST/...) and [duration] for helpful timing info.
  void _handleResponse(
    http.Response response, {
    required String method,
    required Duration duration,
  }) {
    final statusCode = response.statusCode;
    final url = response.request?.url;
    final ms = duration.inMilliseconds;

    if (statusCode == 200) {
      _logger.i(
        '[$method] $url -> SUCCESS ($statusCode) in ${ms}ms',
      );
    } else {
      _logger.w(
        '[$method] $url -> ERROR ($statusCode) in ${ms}ms\nBody: ${response.body}',
      );
    }
  }
}
