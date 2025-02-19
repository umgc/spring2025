class Grade {
  final int id;
  final int userid;
  final double grade;  // Convert from string in the JSON
  final int grader;
  final DateTime timecreated;
  final DateTime timemodified;

  Grade({
    required this.id,
    required this.userid,
    required this.grade,
    required this.grader,
    required this.timecreated,
    required this.timemodified,
  });

  // Parse grade JSON
  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      userid: json['userid'] ?? 0,
      // Parsing the grade as a double from a string
      grade: json['grade'] != null ? double.parse(json['grade']) : 0.0,
      grader: json['grader'] ?? 0,
      timecreated: DateTime.fromMillisecondsSinceEpoch(json['timecreated'] * 1000),
      timemodified: DateTime.fromMillisecondsSinceEpoch(json['timemodified'] * 1000),
    );
  }
}