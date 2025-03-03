import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';

class Course implements LearningLensInterface {
  int id;
  String shortName;
  String fullName;
  DateTime startdate;
  DateTime enddate;
  String courseId;
  String? subject;

  List<Quiz>? quizzes;
  List<Assignment>? essays;
  int? quizTopicId;
  int? essayTopicId;

  Course(this.id, this.shortName, this.courseId, this.fullName, this.startdate,
      this.enddate, {this.subject, this.quizzes, this.essays});

  Course.empty()
      : id = 0,
        shortName = '',
        courseId = '',
        fullName = '',
        startdate = DateTime.now(),
        enddate = DateTime.now(),
        subject = null,
        quizzes = null,
        essays = null;

  static String dateFormatted(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Course fromMoodleJson(Map<String, dynamic> json) {
    return Course(
      json['id'],
      json['shortname'] ?? '',
      json['idnumber'] ?? '',
      json['fullname'] ?? '',
      DateTime.fromMillisecondsSinceEpoch(json['startdate'] * 1000),
      DateTime.fromMillisecondsSinceEpoch(json['enddate'] * 1000),
      subject: json['subject'] ?? 'General',
    );
  }

  @override
  Course fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Figure out an end date.
    return Course(
      int.parse(json['id']),
      json['name'],
      json['section'],
      json['name'],
      DateTime.parse(json['creationTime']),
      DateTime.parse(json['updateTime']).add(Duration(days: 180)),
    );
  }

  @override
  String toString() {
    return "$shortName ($fullName) $id";
  }
}
