import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<http.Response> httpPost(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    try {
      final response = await http.post(url, headers: headers, body: body, encoding: encoding);

      if (response.statusCode == 200) {
        print('✅ SUCCESS: ${response.statusCode}');
        // print('Response Body: ${response.body}');
      } else {
        print('❌ ERROR: ${response.statusCode}');
        print('Error Message: ${response.body}');
      }

      return response;
    } catch (e) {
      print('❌ Exception: $e');
      rethrow; // Propagate the exception
    }
  }

  Future<http.Response> httpGet(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        print('✅ SUCCESS: $url : ${response.statusCode}');
        // print('Response Body: ${response.body}');r
      } else {
        print('❌ ERROR: ${response.statusCode}');
        print('Error Message: ${response.body}');
      }

      return response;
    } catch (e) {
      print('❌ Exception: $e');
      rethrow; // Propagate the exception
    }
  }
}
