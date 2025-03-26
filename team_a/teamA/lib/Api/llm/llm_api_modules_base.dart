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

  // Define a constant instruction to append to all prompts
  static const String _noMarkdownInstruction = 
      " Respond in plain text, without Markdown formatting (like *, **, __, #, ##, ###, and other markdown formatting). Do not use Markdown syntax in your response. Also, do not include apostrophes (') in your response. ";

  // Abstract method that subclasses must implement
  Future<String> _generate(String prompt);

  // Public method that wraps the prompt with the no-Markdown instruction
  Future<String> generate(String prompt) async {
    // Append the instruction to the original prompt
    final modifiedPrompt = "$prompt$_noMarkdownInstruction";
    return await _generate(modifiedPrompt);
  }
}
