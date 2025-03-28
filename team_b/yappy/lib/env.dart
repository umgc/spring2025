import 'package:envied/envied.dart';

// part 'env.g.dart'; // Uncomment this line to generate the env.g.dart file

// Run `flutter pub run build_runner build` to generate the env.g.dart file
@Envied(path: '.env')
abstract class Env {
  // Use the following values instead for local testing:
  // "_Env.apiKey;"
  // "_Env.awsRegion;"
  // "_Env.awsAccessKey;"
  // "_Env.awsSecretKey;"
  // Otherwise, provide an API key within the application's settings while running

  @EnviedField(varName: 'OPENAI_API_KEY')
  static String apiKey = '';

  @EnviedField(varName: 'AWS_REGION')
  static const String awsRegion = '';
  
  @EnviedField(varName: 'AWS_ACCESS_KEY', obfuscate: true)
  static final String awsAccessKey = '';
  
  @EnviedField(varName: 'AWS_SECRET_KEY', obfuscate: true)
  static final String awsSecretKey = '';
}
