class QuestionData {
  final String question;
  final List<String> options;

  QuestionData({required this.question, required this.options});
}

// Define a class to hold the form title, questions, and additional assignment details
class FormData {
  final String title;
  final List<QuestionData> questions;
  final String? startDate;
  final String? endDate;
  final String? formUrl;
  final String? status;

  FormData({
    required this.title,
    required this.questions,
    this.startDate,
    this.endDate,
    this.formUrl,
    this.status,
  });
}


