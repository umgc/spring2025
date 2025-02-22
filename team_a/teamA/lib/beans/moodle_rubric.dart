import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/moodle_rubric_criteria.dart';

class MoodleRubric implements LearningLensInterface {
  final String title;
  final List<MoodleRubricCriteria> criteria;

  MoodleRubric({required this.title, required this.criteria});

  // Empty constructor
  MoodleRubric.empty()
      : title = 'Rubric',
        criteria = [];

  @override
  MoodleRubric fromMoodleJson(Map<String, dynamic> json) {
    var criteriaList = (json['rubric_criteria'] as List)
        .map((c) => MoodleRubricCriteria.fromMoodleJson(c))
        .toList();

    return MoodleRubric(
      title: json['criteria_title'] ?? 'Rubric',
      criteria: criteriaList,
    );
  }

  @override
  MoodleRubric fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Dinesh, try to map the Google JSON to the MoodleRubric object and maybe change this class to be more generic
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'criteria': criteria.map((c) => c.toJson()).toList(),
    };
  }
}
