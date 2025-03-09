import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Override implements LearningLensInterface {
  int id;
  String type;
  int assignmentId;
  String assignmentName;
  int courseId;
  String courseName;
  int userid;
  String fullname;
  DateTime? endTime;
  DateTime? timelimit;
  DateTime? cutoffTime;
  int? attempts;

  Override(
    this.id,
    this.type,
    this.assignmentId,
    this.assignmentName,
    this.courseId,
    this.courseName,
    this.userid,
    this.fullname,
    this.endTime,
    this.timelimit,
    this.cutoffTime,
    this.attempts,
  );

  Override.empty()
      : id = 0,
        type = 'quiz',
        assignmentId = 0,
        assignmentName = '',
        courseId = 0,
        courseName = '',
        userid = 0,
        fullname = '',
        endTime = null,
        timelimit = null,
        cutoffTime = null,
        attempts = 0;

  @override
  Override fromMoodleJson(Map<String, dynamic> json) {
    return Override(
      json['override_id'],
      json['assignment_type'],
      json['assignment_id'],
      json['assignment_name'],
      json['course_id'],
      json['course_name'],
      json['userid'],
      json['fullname'],
      json['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['end_time'] * 1000)
          : null,
      json['timelimit'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timelimit'] * 1000)
          : null,
      json['cutoff_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['cutoff_time'] * 1000)
          : null,
      json['attempts']
    );
  }

  @override
  String toString() {
    return "Override(user: $fullname | assignment: $assignmentName | course: $courseName)";
  }

  @override
  Override fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Map Google Classroom JSON to Participant.
    throw UnimplementedError();
  }
}
