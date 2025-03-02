import 'package:envied/envied.dart';

part 'env.g.dart';

// Run `flutter pub run build_runner build` to generate the env.g.dart file
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'OPENAI_API_KEY')
  static String apiKey = _Env.apiKey;
}