abstract class LearningLensInterface {
  // Force all subclasses to implement this method
  LearningLensInterface fromMoodleJson(Map<String, dynamic> json);

  // TODO: Implement this method
  LearningLensInterface fromGoogleJson(Map<String, dynamic> json);

}
