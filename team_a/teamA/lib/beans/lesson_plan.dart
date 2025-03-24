import 'package:learninglens_app/beans/learning_lens_interface.dart';

class LessonPlan implements LearningLensInterface {
  final int id;
  final String name;
  final String intro;
  final int timemodified;

  LessonPlan({
    required this.id,
    required this.name,
    required this.intro,
    required this.timemodified,
  });

  // Empty constructor
  LessonPlan.empty()
      : id = 0,
        name = '',
        intro = '',
        timemodified = 0;

  @override
  LessonPlan fromMoodleJson(Map<String, dynamic> json) {
    return LessonPlan(
      id: json['id'],
      name: json['name'],
      intro: json['intro'],
      timemodified: json['timemodified'],
    );
  }

 @override
  LessonPlan fromGoogleJson(Map<String, dynamic> json) {
    print('LessonPlan.fromGoogleJson: $json');
    
    return LessonPlan(
    id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0, // Ens
    name: json['title'] ?? '',
    intro: json['description'] ?? '',
     timemodified: json['updateTime'] != null 
        ? DateTime.parse(json['updateTime']).millisecondsSinceEpoch // Convert to int
        : 0,
    );
  }
}
