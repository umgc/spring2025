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
        modelType: 'zipformer',
      );
    default:
      throw ArgumentError('Unsupported type: $type');
  }
}
