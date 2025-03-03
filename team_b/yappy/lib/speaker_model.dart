import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<String> getSpeakerModel(
    {required int type}) async {
  final modelDir = 'assets';
  switch (type) {
    case 0:
      return await copyAssetFile('$modelDir/3dspeaker_speech_eres2net_sv_en_voxceleb_16k.onnx');
    default:
      throw ArgumentError('Unsupported type: $type');
    }
  }