import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Participant implements LearningLensInterface {
  final int id;
  // final String username;
  final String fullname;
  final String firstname;
  final String lastname;
  final List<String> roles;

  Participant({
    required this.id,
    // required this.username,
    required this.fullname,
    required this.firstname,
    required this.lastname,
    required this.roles,
  });

  // Empty constructor
  Participant.empty()
      : id = 0,
        // username = '',
        fullname = '',
        firstname = '',
        lastname = '',
        roles = [];

  // Factory constructor for creating a new Participant instance from a JSON map
  @override
  Participant fromMoodleJson(Map<String, dynamic> json) {
    // Convert roles if they exist, and map them from the 'roles' field in the JSON
    List<String> rolesList = [];
    if (json['roles'] != null) {
      rolesList = (json['roles'] as List<dynamic>)
          .map((role) => role['shortname'] as String)
          .toList();
    }

    return Participant(
      id: json['id'] as int,
      // username: json['username'] as String,
      fullname: json['fullname'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      roles: rolesList,
    );
  }
}