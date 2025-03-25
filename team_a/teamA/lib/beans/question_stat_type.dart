class QuestionStatsType {
  final int id;
  final String name;
  final String questionText;
  final String questionType;
  final int numCorrect;
  final int numIncorrect;
  final int numPartial;
  final int totalAttempts;

  QuestionStatsType({
    required this.id,
    required this.name,
    required this.questionText,
    required this.questionType,
    required this.numCorrect,
    required this.numIncorrect,
    required this.numPartial,
    required this.totalAttempts,
  });

  // Optional: a factory constructor to build from JSON
  factory QuestionStatsType.fromJson(Map<String, dynamic> json) {
    return QuestionStatsType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      questionText: json['questiontext'] ?? '',
      questionType: json['qtype'] ?? '',
      numCorrect: json['numcorrect'] ?? 0,
      numIncorrect: json['numincorrect'] ?? 0,
      numPartial: json['numpartial'] ?? 0,
      totalAttempts: json['totalattempts'] ?? 0,
    );
  }
}
