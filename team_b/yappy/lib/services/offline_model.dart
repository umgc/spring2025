import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'model_manager.dart';

Future<sherpa_onnx.OfflineModelConfig> getOfflineModelConfig(
    {required int type}) async {
  final modelManager = ModelManager();
  
  switch (type) {
    case 0:
      final modelType = await modelManager.getModelTypeString('offline') ?? 'whisper';
      
      return sherpa_onnx.OfflineModelConfig(
        whisper: sherpa_onnx.OfflineWhisperModelConfig(
          encoder: await modelManager.getModelPath('offline', 'offline_encoder.onnx'),
          decoder: await modelManager.getModelPath('offline', 'offline_decoder.onnx'),
        ),
        tokens: await modelManager.getModelPath('offline', 'offline_tokens.txt'),
        modelType: modelType,
        debug: false,
        numThreads: 1
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}