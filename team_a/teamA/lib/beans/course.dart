import 'package:learninglens_app/beans/quiz.dart';
import 'package:learninglens_app/beans/assignment.dart';

// Represents a course in Moodle.
class Course {
  int id;
  String shortName;
  String fullName;
  DateTime startdate;
  DateTime enddate;
  String courseId;

  List<Quiz>? quizzes;
  List<Assignment>? essays;

  // Barebones constructor.
  Course(this.id, this.shortName, this.courseId, this.fullName, this.startdate, this.enddate, [this.quizzes, this.essays]);

  static String dateFormatted(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Json factory constructor.
  factory Course.fromMoodleJson(Map<String, dynamic> json) {
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
  String toString(){
    return "$shortName ($fullName) $id";
  }
}