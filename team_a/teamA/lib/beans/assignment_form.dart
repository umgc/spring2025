// Object to pass user-specified parameters to LLM API.
class AssignmentForm {
  String? gradingCriteria;
  String subject;
  String topic;
  String gradeLevel;
  int maximumGrade;
  int? assignmentCount;
  int trueFalseCount;
  int shortAnswerCount;
  int multipleChoiceCount;
  String? codingLanguage;
  String title;

  AssignmentForm(
      {required this.subject,
      required this.topic,
      required this.gradeLevel,
      required this.title,
      required this.trueFalseCount,
      required this.shortAnswerCount,
      required this.multipleChoiceCount,
      required this.maximumGrade,
      this.assignmentCount,
      this.gradingCriteria,
      this.codingLanguage});
}