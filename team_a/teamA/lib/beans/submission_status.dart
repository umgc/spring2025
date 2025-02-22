import 'package:learninglens_app/beans/learning_lens_interface.dart';

class SubmissionStatus implements LearningLensInterface {
  final int assignmentId;
  final int userId;
  final String status;
  final DateTime? timeSubmitted;
  final DateTime? timeGraded;
  final double? grade;
  final bool needsGrading;

  SubmissionStatus({
    required this.assignmentId,
    required this.userId,
    required this.status,
    this.timeSubmitted,
    this.timeGraded,
    this.grade,
    required this.needsGrading,
  });

  // Empty constructor
  SubmissionStatus.empty()
      : assignmentId = 0,
        userId = 0,
        status = 'unknown',
        timeSubmitted = null,
        timeGraded = null,
        grade = null,
        needsGrading = false;

  // Factory method to create a SubmissionStatus object from a JSON response
  @override
  SubmissionStatus fromMoodleJson(Map<String, dynamic> json) {
    return SubmissionStatus(
      assignmentId: json['assignid'] ?? 0,
      userId: json['userid'] ?? 0,
      status: json['lastattempt']['submission']['status'] ?? 'unknown',
      timeSubmitted: json['lastattempt']['submission']['timemodified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['lastattempt']['submission']['timemodified'] * 1000)
          : null,
      timeGraded: json['lastattempt']['grades'] != null &&
              json['lastattempt']['grades']['grade'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['lastattempt']['grades']['timemodified'] * 1000)
          : null,
      grade: json['lastattempt']['grades'] != null &&
              json['lastattempt']['grades']['grade'] != null
          ? double.tryParse(json['lastattempt']['grades']['grade'].toString())
          : null,
      needsGrading: json['lastattempt']['gradingstatus'] == 'notgraded',
    );
  }

  @override
  SubmissionStatus fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Dinesh, try to map the Google JSON to the SubmissionStatus object
    throw UnimplementedError();
  }

  // Convert the SubmissionStatus object back to JSON if necessary
  Map<String, dynamic> toJson() {
    return {
      'assignid': assignmentId,
      'userid': userId,
      'status': status,
      'timemodified': timeSubmitted?.millisecondsSinceEpoch,
      'timegraded': timeGraded?.millisecondsSinceEpoch,
      'grade': grade,
      'needsgrading': needsGrading,
    };
  }
}
