<<<<<<< HEAD
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<String> getSpeakerModel(
    {required int type}) async {
  final modelDir = 'assets';
  switch (type) {
    case 0:
      return await copyAssetFile('$modelDir/3dspeaker_speech_eres2net_sv_en_voxceleb_16k.onnx');
=======
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> getSpeakerModel(
    {required int type}) async {
  final appDir = await getApplicationCacheDirectory();
  final modelDir = Directory('${appDir.path}/models');
  switch (type) {
    case 0:
      return '${modelDir.path}/3dspeaker_speech_eres2net_sv_en_voxceleb_16k.onnx';
>>>>>>> developer
    default:
      throw ArgumentError('Unsupported type: $type');
    }
  }