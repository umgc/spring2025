import 'package:learninglens_app/beans/learning_lens_interface.dart';

class QuestionType implements LearningLensInterface {
  final int id;
  final String name;
  final String questionText;
  final String questionType;

  QuestionType({
    required this.id,
    required this.name,
    required this.questionText,
    required this.questionType,
  });

  QuestionType.empty()
      : id = 0,
        name = '',
        questionText = '',
        questionType = '';

  @override
  QuestionType fromMoodleJson(Map<String, dynamic> json) {
    return QuestionType(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unnamed Question',
      questionText: json['questiontext'] as String? ?? 'No Question Text',
      questionType: json['qtype'] as String? ?? 'unknown',
    );
  }

  @override
  QuestionType fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Map Google Classroom JSON to Questions object.
    throw UnimplementedError();
  }

  @override
  String toString() {
    return "Questions(id: $id, name: $name, type: $questionType, text: $questionText)";
  }
}
