import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getSpeakerModel(
    {required int type}) async {
  final appDir = await getApplicationCacheDirectory();
  final modelDir = Directory('${appDir.path}/models');
  switch (type) {
    case 0:
      return '${modelDir.path}/3dspeaker_speech_eres2net_sv_en_voxceleb_16k.onnx';
    default:
      throw ArgumentError('Unsupported type: $type');
    }
  }