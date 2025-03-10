import './model_manager.dart';

Future<String> getSpeakerModel({required int type}) async {
  final modelManager = ModelManager();
  
  switch (type) {
    case 0:
      return await modelManager.getModelPath('speaker', 'speaker_model.onnx');
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}