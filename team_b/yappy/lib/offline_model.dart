import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OfflineModelConfig> getOfflineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0:
      final modelDir = 'assets/sherpa-onnx-whisper-tiny.en';
      return sherpa_onnx.OfflineModelConfig(
        whisper: sherpa_onnx.OfflineWhisperModelConfig(
          encoder: await copyAssetFile('$modelDir/tiny.en-encoder.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/tiny.en-decoder.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tiny.en-tokens.txt'),
        modelType: 'whisper',
        debug: false,
        numThreads: 1
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}
