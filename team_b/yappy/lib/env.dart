import 'package:envied/envied.dart';

// part 'env.g.dart'; // Uncomment this line to generate the env.g.dart file

// Run `flutter pub run build_runner build` to generate the env.g.dart file
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY')
  // Use this value instead for local testing: "_Env.apiKey;"
  // Otherwise, provide an API key within the application's settings while running
  static String apiKey = '';

  @EnviedField(varName: 'AWS_REGION')
  static const String awsRegion = _Env.awsRegion;
  
  @EnviedField(varName: 'AWS_ACCESS_KEY', obfuscate: true)
  static final String awsAccessKey = _Env.awsAccessKey;
  
  @EnviedField(varName: 'AWS_SECRET_KEY', obfuscate: true)
  static final String awsSecretKey = _Env.awsSecretKey;
}
