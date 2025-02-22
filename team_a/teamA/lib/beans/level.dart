class Level {
  final int id;
  final String description;
  final int score;

  Level({required this.id, required this.description, required this.score});

  factory Level.fromMoodleJson(Map<String, dynamic> json) 
  {
    return Level(
      id: json['id'] ?? 0,
      description: json['definition'] ?? '',
      score: json['score'] ?? 0,
    );
  }

   Map<String, dynamic> toJson() 
   {
    return {
      'id': id,
      'description': description,
      'score': score,
    };
   }
}