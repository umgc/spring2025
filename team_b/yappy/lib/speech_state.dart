import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './utils.dart';
import './online_model.dart';
import './offline_model.dart';

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer() async {
  final type = 4;

  final modelConfig = await getOnlineModelConfig(type: type);
  final config = sherpa_onnx.OnlineRecognizerConfig(
    model: modelConfig,
    ruleFsts: '',
  );

  return sherpa_onnx.OnlineRecognizer(config);
}

Future<sherpa_onnx.OfflineRecognizer> createOfflineRecognizer() async {
  final type = 0;

  final modelConfig = await getOfflineModelConfig(type: type);
  final config = sherpa_onnx.OfflineRecognizerConfig(
    model: modelConfig
  );

  return sherpa_onnx.OfflineRecognizer(config);
}

class AudioSegment {
  final Float32List samples;
  final int sampleRate;
  final String streamingText;
  
  AudioSegment({
    required this.samples,
    required this.sampleRate,
    required this.streamingText,
  });
}

class SpeechState extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();
  
  RecordState recordState = RecordState.stop;
  bool isInitialized = false;
  String streamingText = '';
  int index = 0;
  
  // First pass - streaming recognition
  sherpa_onnx.OnlineRecognizer? onlineRecognizer;
  sherpa_onnx.OnlineStream? onlineStream;

  // Second pass - Whisper offline recognition
  sherpa_onnx.OfflineRecognizer? offlineRecognizer;

  // Buffer for collecting samples between endpoints
  List<Float32List> currentSegmentSamples = [];
  final int sampleRate = 16000;

  // Store segments that need offline processing
  List<AudioSegment> pendingSegments = [];
  bool isProcessingOffline = false;

  Future<void> initialize() async {
    if (!isInitialized) {
      // init online recognizer
      sherpa_onnx.initBindings();
      onlineRecognizer = await createOnlineRecognizer();
      onlineStream = onlineRecognizer?.createStream();
      // init offline recognizer
      offlineRecognizer = await createOfflineRecognizer();

      isInitialized = true;
      notifyListeners();
    }
  }

Future<void> processSegmentOffline(AudioSegment segment) async {
    final offlineStream = offlineRecognizer!.createStream();
    
    offlineStream.acceptWaveform(
      samples: segment.samples,
      sampleRate: segment.sampleRate
    );
    
    offlineRecognizer!.decode(offlineStream);
    final result = offlineRecognizer!.getResult(offlineStream);
    
    // Replace the streaming result with the offline result
    final oldText = segment.streamingText;
    final newText = result.text;
    
    final currentText = controller.text;
    final updatedText = currentText.replaceAll(oldText, newText);
    
    controller.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: updatedText.length),
    );
    
    offlineStream.free();
  }

  Future<void> processPendingSegments() async {
    if (pendingSegments.isEmpty || isProcessingOffline) return;
    
    isProcessingOffline = true;
    
    for (final segment in pendingSegments) {
      await processSegmentOffline(segment);
    }
    
    pendingSegments.clear();
    isProcessingOffline = false;
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
        currentSegmentSamples.clear();
        notifyListeners();

        recordStream.listen(
          (data) {
            final samplesFloat32 = convertBytesToFloat32(Uint8List.fromList(data));
            
            // Add samples to current segment buffer
            currentSegmentSamples.add(samplesFloat32);

            onlineStream!.acceptWaveform(
              samples: samplesFloat32, 
              sampleRate: sampleRate
            );
            
            while (onlineRecognizer!.isReady(onlineStream!)) {
              onlineRecognizer!.decode(onlineStream!);
            }
            
            final text = onlineRecognizer!.getResult(onlineStream!).text;

            if (text.isNotEmpty) {
              streamingText = '$index: $text';
              controller.value = TextEditingValue(
                text: streamingText,
                selection: TextSelection.collapsed(offset: streamingText.length),
              );
            }

            if (onlineRecognizer!.isEndpoint(onlineStream!)) {
              // Store the current segment for offline processing
              if (currentSegmentSamples.isNotEmpty && streamingText.isNotEmpty) {
                // Combine all Float32Lists into a single one
                final combinedSamples = Float32List(currentSegmentSamples.fold<int>(
                  0, (sum, list) => sum + list.length));
                var offset = 0;
                for (var samples in currentSegmentSamples) {
                  combinedSamples.setRange(offset, offset + samples.length, samples);
                  offset += samples.length;
                }

                pendingSegments.add(AudioSegment(
                  samples: combinedSamples,
                  sampleRate: sampleRate,
                  streamingText: streamingText,
                ));
                
                // Process with Whisper in the background
                processPendingSegments();
              }
              
              // Reset for next segment
              onlineRecognizer!.reset(onlineStream!);
              currentSegmentSamples.clear();
              index += 1;
            }
          },
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> stopRecording() async {
    // Process any remaining audio with Whisper
    if (currentSegmentSamples.isNotEmpty && streamingText.isNotEmpty) {
      // Combine all Float32Lists into a single one
      final combinedSamples = Float32List(currentSegmentSamples.fold<int>(
        0, (sum, list) => sum + list.length));
      var offset = 0;
      for (var samples in currentSegmentSamples) {
        combinedSamples.setRange(offset, offset + samples.length, samples);
        offset += samples.length;
      }

      pendingSegments.add(AudioSegment(
        samples: combinedSamples,
        sampleRate: sampleRate,
        streamingText: streamingText,
      ));
    }

    onlineStream!.free();
    onlineStream = onlineRecognizer?.createStream();
    await audioRecorder.stop();
    recordState = RecordState.stop;

    // Process final segments
    await processPendingSegments();

    currentSegmentSamples.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    audioRecorder.dispose();
    onlineStream?.free();
    onlineRecognizer?.free();
    offlineRecognizer?.free();
    super.dispose();
  }
}