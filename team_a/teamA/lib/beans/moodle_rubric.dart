import 'package:learninglens_app/beans/moodle_rubric_criteria.dart';

class MoodleRubric {
  final String title;
  final List<MoodleRubricCriteria> criteria;

  MoodleRubric({required this.title, required this.criteria});

  factory MoodleRubric.fromMoodleJson(Map<String, dynamic> json) {
    var criteriaList = (json['rubric_criteria'] as List)
        .map((c) => MoodleRubricCriteria.fromMoodleJson(c))
        .toList();

    return MoodleRubric(
      title: json['criteria_title'] ?? 'Rubric',
      criteria: criteriaList,
    );
  }

  Map<String, dynamic> toJson() 
  {
    return {
      'title': title,
      'criteria': criteria.map((c) => c.toJson()).toList(),
    };
  }
}