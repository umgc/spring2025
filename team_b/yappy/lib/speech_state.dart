import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './utils.dart';
import './online_model.dart';

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer() async {
  final type = 4;

  final modelConfig = await getOnlineModelConfig(type: type);
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: modelConfig,
    ruleFsts: '',
  );

  return sherpa_onnx.OnlineRecognizer(config);
}

class SpeechState extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();
  
  RecordState recordState = RecordState.stop;
  bool isInitialized = false;
  String last = '';
  int index = 0;
  
  sherpa_onnx.OnlineRecognizer? recognizer;
  sherpa_onnx.OnlineStream? stream;
  final int sampleRate = 16000;

  Future<void> initialize() async {
    if (!isInitialized) {
      sherpa_onnx.initBindings();
      recognizer = await createOnlineRecognizer();
      stream = recognizer?.createStream();
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> toggleRecording() async {
    if (recordState == RecordState.stop) {
      await startRecording();
    } else {
      await stopRecording();
    }
  }

  Future<void> startRecording() async {
    if (!isInitialized) {
      await initialize();
    }

    try {
      if (await audioRecorder.hasPermission()) {
        const encoder = AudioEncoder.pcm16bits;
        
        const config = RecordConfig(
          encoder: encoder,
          sampleRate: 16000,
          numChannels: 1,
        );

        final recordStream = await audioRecorder.startStream(config);
        recordState = RecordState.record;
        notifyListeners();

        recordStream.listen(
          (data) {
            final samplesFloat32 = convertBytesToFloat32(Uint8List.fromList(data));
            
            stream!.acceptWaveform(
              samples: samplesFloat32, 
              sampleRate: sampleRate
            );
            
            while (recognizer!.isReady(stream!)) {
              recognizer!.decode(stream!);
            }
            
            final text = recognizer!.getResult(stream!).text;
            String textToDisplay = last;
            
            if (text.isNotEmpty) {
              if (last.isEmpty) {
                textToDisplay = '$index: $text';
              } else {
                textToDisplay = '$index: $text\n$last';
              }
            }

            if (recognizer!.isEndpoint(stream!)) {
              recognizer!.reset(stream!);
              if (text.isNotEmpty) {
                last = textToDisplay;
                index += 1;
              }
            }

            controller.value = TextEditingValue(
              text: textToDisplay,
              selection: TextSelection.collapsed(offset: textToDisplay.length),
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> stopRecording() async {
    stream!.free();
    stream = recognizer?.createStream();
    await audioRecorder.stop();
    recordState = RecordState.stop;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    audioRecorder.dispose();
    stream?.free();
    recognizer?.free();
    super.dispose();
  }
}