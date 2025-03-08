import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OfflineModelConfig> getOfflineModelConfig(
    {required int type}) async {
  final appDir = await getApplicationCacheDirectory();
  final modelDir = Directory('${appDir.path}/models');
  switch (type) {
    case 0:
      final fullDir = '${modelDir.path}/sherpa-onnx-whisper-tiny.en';
      return sherpa_onnx.OfflineModelConfig(
        whisper: sherpa_onnx.OfflineWhisperModelConfig(
          encoder: '$fullDir/tiny.en-encoder.int8.onnx',
          decoder: '$fullDir/tiny.en-decoder.int8.onnx',
        ),
        tokens: '$fullDir/tiny.en-tokens.txt',
        modelType: 'whisper',
        debug: false,
        numThreads: 1
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}
