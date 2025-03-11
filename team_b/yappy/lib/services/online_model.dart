import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'model_manager.dart';

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  final modelManager = ModelManager();
  
  switch (type) {
    case 0:
      final modelType = await modelManager.getModelTypeString('online') ?? 'zipformer';
      
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await modelManager.getModelPath('online', 'online_encoder.onnx'),
          decoder: await modelManager.getModelPath('online', 'online_decoder.onnx'),
          joiner: await modelManager.getModelPath('online', 'online_joiner.onnx'),
        ),
        tokens: await modelManager.getModelPath('online', 'online_tokens.txt'),
        modelType: modelType,
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}