import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';

// Represents a course in Moodle.
class Course implements LearningLensInterface {
  int id;
  String shortName;
  String fullName;
  DateTime startdate;
  DateTime enddate;
  String courseId;

  List<Quiz>? quizzes;
  List<Assignment>? essays;

  // Barebones constructor.
  Course(this.id, this.shortName, this.courseId, this.fullName, this.startdate,
      this.enddate,
      [this.quizzes, this.essays]);

  // Empty constructor.
  Course.empty()
      : id = 0,
        shortName = '',
        courseId = '',
        fullName = '',
        startdate = DateTime.now(),
        enddate = DateTime.now(),
        quizzes = null,
        essays = null;

  static String dateFormatted(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Json factory constructor.
  @override
  Course fromMoodleJson(Map<String, dynamic> json) {
    return Course(
      json['id'],
      json['shortname'],
      json['idnumber'],
      json['fullname'],
      DateTime.fromMillisecondsSinceEpoch(json['startdate'] * 1000),
      DateTime.fromMillisecondsSinceEpoch(json['enddate'] * 1000),
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
