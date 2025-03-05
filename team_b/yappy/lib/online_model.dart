<<<<<<< HEAD
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import './utils.dart';

// Remember to change `assets` in ../pubspec.yaml
// and download files to ../assets
Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  switch (type) {
    case 0:
      final modelDir =
          'assets/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder:
              await copyAssetFile('$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
          decoder: await copyAssetFile('$modelDir/decoder-epoch-99-avg-1.onnx'),
          joiner: await copyAssetFile('$modelDir/joiner-epoch-99-avg-1.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer',
      );
    case 1:
      final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-2023-06-26';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-99-avg-1-chunk-16-left-128.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-99-avg-1-chunk-16-left-128.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-99-avg-1-chunk-16-left-128.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 2:
      final modelDir =
          'assets/icefall-asr-zipformer-streaming-wenetspeech-20230615';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/exp/encoder-epoch-12-avg-4-chunk-16-left-128.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/exp/decoder-epoch-12-avg-4-chunk-16-left-128.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/exp/joiner-epoch-12-avg-4-chunk-16-left-128.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/data/lang_char/tokens.txt'),
        modelType: 'zipformer2',
      );
    case 3:
      final modelDir = 'assets/sherpa-onnx-streaming-zipformer-fr-2023-04-14';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-29-avg-9-with-averaged-model.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-29-avg-9-with-averaged-model.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-29-avg-9-with-averaged-model.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
        modelType: 'zipformer',
      );
    case 4:
      final modelDir = 'assets/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: await copyAssetFile(
              '$modelDir/encoder-epoch-99-avg-1.int8.onnx'),
          decoder: await copyAssetFile(
              '$modelDir/decoder-epoch-99-avg-1.onnx'),
          joiner: await copyAssetFile(
              '$modelDir/joiner-epoch-99-avg-1.int8.onnx'),
        ),
        tokens: await copyAssetFile('$modelDir/tokens.txt'),
=======
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

Future<sherpa_onnx.OnlineModelConfig> getOnlineModelConfig(
    {required int type}) async {
  final appDir = await getApplicationCacheDirectory();
  final modelDir = Directory('${appDir.path}/models');
  switch (type) {
    case 4:
      final fullDir = '${modelDir.path}/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17-mobile';
      return sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$fullDir/encoder-epoch-99-avg-1.int8.onnx',
          decoder: '$fullDir/decoder-epoch-99-avg-1.onnx',
          joiner: '$fullDir/joiner-epoch-99-avg-1.int8.onnx',
        ),
        tokens: '$fullDir/tokens.txt',
>>>>>>> developer
        modelType: 'zipformer',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}
