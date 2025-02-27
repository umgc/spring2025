import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Grade implements LearningLensInterface {
  final int id;
  final int userid;
  final double grade;
  final int grader;
  final DateTime timecreated;
  final DateTime timemodified;

  Grade({
    required this.id,
    required this.userid,
    required this.grade,
    required this.grader,
    required this.timecreated,
    required this.timemodified,
  });

  Grade.empty()
      : id = 0,
        userid = 0,
        grade = 0.0,
        grader = 0,
        timecreated = DateTime.now(),
        timemodified = DateTime.now();

  @override
  Grade fromMoodleJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      userid: json['userid'] ?? 0,
      grade: json['grade'] != null ? double.parse(json['grade']) : 0.0,
      grader: json['grader'] ?? 0,
      timecreated: DateTime.fromMillisecondsSinceEpoch(json['timecreated'] * 1000),
      timemodified: DateTime.fromMillisecondsSinceEpoch(json['timemodified'] * 1000),
    );
  }

  @override
  Grade fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Map Google Classroom JSON to Grade.
    throw UnimplementedError();
  }
}
