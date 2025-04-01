// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}
//This is the abstract class for the LLM API module
//It has a single method called generate which takes a string prompt and returns a string
abstract class LLM {
  final String apiKey;
  String get url; 
  String get model;

  LLM(this.apiKey);

  // Abstract method that subclasses must implement
  Future<String> generate(String prompt);

 
}
