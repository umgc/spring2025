import 'dart:convert';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/services/api_service.dart';

class AssessmentGenerator {
  final String serverUrl;

  AssessmentGenerator({required this.serverUrl});

  Future<Quiz> generateAssessment(String queryPrompt) async {
    final response = await ApiService().httpPost(
      Uri.parse('$serverUrl/generateAssessment'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'QueryPrompt': queryPrompt},
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final aiResponse = responseBody['assessment'];
      return Quiz.fromXmlString(aiResponse);
    } else {
      throw Exception('Failed to generate assessment');
    }
  }
}
