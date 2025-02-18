import 'package:learninglens_app/beans/submission.dart';
import 'package:learninglens_app/beans/grade.dart';

class SubmissionWithGrade {
  final Submission submission;
  final Grade? grade;

  SubmissionWithGrade({
    required this.submission,
    this.grade,
  });
}