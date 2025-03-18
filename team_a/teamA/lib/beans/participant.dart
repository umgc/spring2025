import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Participant implements LearningLensInterface {
  final int id;
  final String fullname;
  final String firstname;
  final String lastname;
  final List<String> roles;
  double? avgGrade;

  Participant({
    required this.id,
    required this.fullname,
    required this.firstname,
    required this.lastname,
    required this.roles,
    this.avgGrade,
  });

  Participant.empty()
      : id = 0,
        fullname = '',
        firstname = '',
        lastname = '',
        roles = [],
        avgGrade = null;

  @override
  Participant fromMoodleJson(Map<String, dynamic> json) {
    // Parse roles from the JSON.
    List<String> rolesList = [];
    if (json['roles'] != null) {
      rolesList = (json['roles'] as List<dynamic>)
          .map((role) => role['shortname'] as String)
          .toList();
    }
    return Participant(
      id: json['id'] as int,
      fullname: json['fullname'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      roles: rolesList,
      // Parse avgGrade if available; otherwise, leave as null.
      avgGrade: json['avggrade'] != null
          ? double.tryParse(json['avggrade'].toString())
          : null,
    );
  }

  @override
  String toString() {
    return fullname;
  }

  @override
  Participant fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Map Google Classroom JSON to Participant.
    throw UnimplementedError();
  }
}
