import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Submission implements LearningLensInterface {
  final int id;
  final int userid;
  final String status;
  final DateTime submissionTime;
  final DateTime? modificationTime;
  final int attemptNumber;
  final int groupId;
  final String gradingStatus;
  final String onlineText;
  final String comments;
  final int assignmentId; // Added field

  Submission({
    required this.id,
    required this.userid,
    required this.status,
    required this.submissionTime,
    this.modificationTime,
    required this.attemptNumber,
    required this.groupId,
    required this.gradingStatus,
    required this.onlineText,
    required this.comments,
    required this.assignmentId,
  });

  // empty constructor
  Submission.empty()
      : id = 0,
        userid = 0,
        status = '',
        submissionTime = DateTime.fromMillisecondsSinceEpoch(0),
        modificationTime = DateTime.fromMillisecondsSinceEpoch(0),
        attemptNumber = 0,
        groupId = 0,
        gradingStatus = '',
        onlineText = '',
        comments = '',
        assignmentId = 0;

  @override
  Submission fromMoodleJson(Map<String, dynamic> json) {
    String onlineText = '';
    String comments = '';

    // Debug: Print entire submission JSON
    // ignore: avoid_print
    print('Processing submission: ${json.toString()}');
    int assignmentId = json['assignmentid'] ?? 0;
    Map<String, dynamic> submission = json['submission'] ?? {};

    if (submission['plugins'] != null && submission['plugins'] is List) {
      for (var plugin in submission['plugins']) {
        // Extract 'onlineText'
        if (plugin['type'] != null &&
            plugin['type'].toString().toLowerCase() == 'onlinetext') {
          var editorFields = plugin['editorfields'];
          if (editorFields != null &&
              editorFields is List &&
              editorFields.isNotEmpty) {
            for (var field in editorFields) {
              if (field['name'] != null &&
                  field['name'].toString().toLowerCase() == 'onlinetext') {
                onlineText = field['text'] ?? '';
                print('Extracted onlineText: $onlineText');
                break; // Exit loop once the correct field is found
              }
            }
          }
        }

        // Extract 'comments'
        if (plugin['type'] != null &&
            plugin['type'].toString().toLowerCase() == 'comments') {
          var editorFields = plugin['editorfields'];
          if (editorFields != null &&
              editorFields is List &&
              editorFields.isNotEmpty) {
            for (var field in editorFields) {
              if (field['name'] != null &&
                  field['name'].toString().toLowerCase() == 'comments') {
                comments = field['text'] ?? '';
                print('Extracted comments: $comments');
                break; // Exit loop once the correct field is found
              }
            }
          }
        }
      }
    } else {
      print('No plugins found in submission.');
    }

    return Submission(
        id: submission['id'] ?? 0,
        userid: submission['userid'] ?? 0,
        status: submission['status'] ?? '',
        submissionTime: submission['timecreated'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                submission['timecreated'] * 1000)
            : DateTime.fromMillisecondsSinceEpoch(0),
        modificationTime: submission['timemodified'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                submission['timemodified'] * 1000)
            : null,
        attemptNumber: submission['attemptnumber'] ?? 0,
        groupId: submission['groupid'] ?? 0,
        gradingStatus: submission['gradingstatus'] ?? '',
        onlineText: onlineText,
        comments: comments,
        assignmentId: assignmentId);
  }

  @override
  Submission fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Dinesh, try to map the Google JSON to the Submission object
    throw UnimplementedError();
  }
}
