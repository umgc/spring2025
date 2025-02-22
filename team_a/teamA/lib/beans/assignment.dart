import 'package:learninglens_app/beans/submission_with_grade.dart';

class Assignment {
  final int? id;
  final String name;
  final String description;
  final DateTime? dueDate;
  final DateTime? allowsubmissionsfromdate;
  final DateTime? cutoffDate;
  final bool isDraft;
  final int maxAttempts;
  final int gradingStatus; // Can use an enum to represent status like "graded", "notgraded"
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

  // Factory method to create an Assignment object from a JSON response
  factory Assignment.fromMoodleJson(Map<String, dynamic> json) {
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
      isDraft: json['submissiondrafts'] == 1, // boolean conversion
      maxAttempts: json['maxattempts'] ?? 0,
      gradingStatus: json['gradingstatus'] ?? 0,
      courseId: json['course'] ?? 0,

    );
  }

  bool isNew(){
    return id == null;
  }

  // Convert the Assignment object back to JSON (useful for POST requests or local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'duedate': dueDate?.millisecondsSinceEpoch,
      'allowsubmissionsfromdate': allowsubmissionsfromdate?.millisecondsSinceEpoch,
      'cutoffdate': cutoffDate?.millisecondsSinceEpoch,
      'submissiondrafts': isDraft ? 1 : 0,
      'maxattempts': maxAttempts,
      'gradingstatus': gradingStatus,
      'course': courseId,

    };
  }
}