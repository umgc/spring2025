import 'package:learninglens_app/beans/learning_lens_interface.dart';

class Level implements LearningLensInterface {
  final int id;
  final String description;
  final int score;

  Level({required this.id, required this.description, required this.score});

  // Empty constructor
  Level.empty()
      : id = 0,
        description = '',
        score = 0;

  @override
  Level fromMoodleJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] ?? 0,
      description: json['definition'] ?? '',
      score: json['score'] ?? 0,
    );
  }

  @override
  Level fromGoogleJson(Map<String, dynamic> json) {
    // TODO: Dinesh, try to map the Google JSON to the Level object
    throw UnimplementedError();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'score': score,
    };
  }
}
