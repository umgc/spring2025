import 'package:learninglens_app/beans/learning_lens_interface.dart';
import 'package:learninglens_app/beans/submission_with_grade.dart';

class Assignment implements LearningLensInterface {
  final int? id;
  final String name;
  final String description;
  final DateTime? dueDate;
  final DateTime? allowsubmissionsfromdate;
  final DateTime? cutoffDate;
  final bool isDraft;
  final int maxAttempts;
  final int gradingStatus;
  final int courseId;

  final List<SubmissionWithGrade>? submissionsWithGrades;

  Assignment({
    this.id,
    required this.name,
    required this.description,
    this.dueDate,
    this.allowsubmissionsfromdate,
    this.cutoffDate,
    required this.isDraft,
    required this.maxAttempts,
    required this.gradingStatus,
    required this.courseId,
    this.submissionsWithGrades,
  });

  Assignment.empty()
      : id = null,
        name = '',
        description = '',
        dueDate = null,
        allowsubmissionsfromdate = null,
        cutoffDate = null,
        isDraft = false,
        maxAttempts = 0,
        gradingStatus = 0,
        courseId = 0,
        submissionsWithGrades = null;

  @override
  Assignment fromMoodleJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Untitled',
      description: json['description'] ?? json['intro'] ?? '',
      dueDate: json['duedate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['duedate'] * 1000)
          : null,
      allowsubmissionsfromdate: json['allowsubmissionsfromdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['allowsubmissionsfromdate'] * 1000)
          : null,
      cutoffDate: json['cutoffdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['cutoffdate'] * 1000)
          : null,
      isDraft: json['submissiondrafts'] == 1,
      maxAttempts: json['maxattempts'] ?? 0,
      gradingStatus: json['gradingstatus'] ?? 0,
      courseId: json['course'] ?? 0,
    );
  }

  @override
  Assignment fromGoogleJson(Map<String, dynamic> json) {
    return Assignment(
      id: int.parse(json['id']),
      name: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime(json['dueDate']['year'], 
                    json['dueDate']['month'], 
                    json['dueDate']['day'])
          : null,
      allowsubmissionsfromdate: json['creationTime'] != null
          ? DateTime.parse(json['creationTime'])
          : null,
      cutoffDate: json['dueDate'] != null
          ? DateTime(json['dueDate']['year'], 
                    json['dueDate']['month'], 
                    json['dueDate']['day'])
          : null,
      isDraft: false,
      maxAttempts: 1,
      gradingStatus: 0, // TODO: figure out grading status
      courseId: int.parse(json['courseId']),
    );
  }
  @override
  String toString() {
    return "$name";
  }

}
