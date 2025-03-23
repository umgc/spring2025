import './model_manager.dart';

Future<String> getVadModel({required int type}) async {
  final modelManager = ModelManager();
  
  switch (type) {
    case 0:
      return await modelManager.getModelPath('vad', 'vad_model.onnx');
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}