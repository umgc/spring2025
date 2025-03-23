import 'package:envied/envied.dart';

// part 'env.g.dart'; // Uncomment this line to generate the env.g.dart file

// Run `flutter pub run build_runner build` to generate the env.g.dart file
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY')
  // Use this value instead for local testing: "_Env.apiKey;"
  // Otherwise, provide an API key within the application's settings while running
  static String apiKey = '';
}
