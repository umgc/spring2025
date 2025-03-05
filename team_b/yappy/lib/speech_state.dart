import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './utils.dart';
import './online_model.dart';
import './offline_model.dart';
<<<<<<< HEAD
import './speaker_model.dart'; 
=======
import './speaker_model.dart';
>>>>>>> developer

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

Future<sherpa_onnx.SpeakerEmbeddingExtractor> createSpeakerExtractor() async {
  final type = 0;

  final model = await getSpeakerModel(type: type);
  final config = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
    model: model,
    numThreads: 2,
    debug: false,
    provider: 'cpu',
  );

  return sherpa_onnx.SpeakerEmbeddingExtractor(config: config);
}

class Conversation {
  final List<RecognizedSegment> segments;
  final String audioFilePath;
  
  Conversation({
    required this.segments,
    required this.audioFilePath,
  });
  
  // Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'segments': segments.map((s) => s.toJson()).toList(),
    'audioFilePath': audioFilePath,
  };
  
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    segments: (json['segments'] as List)
        .map((s) => RecognizedSegment.fromJson(s))
        .toList(),
    audioFilePath: json['audioFilePath'],
  );
  
  // Generate a transcript from the conversation
  String getTranscript({bool includeSpeakerTags = true}) {
    final buffer = StringBuffer();
    RecognizedSegment? lastSegment;
    
    for (final segment in segments) {
      if (segment.text.isEmpty) continue;
      
      if (buffer.isNotEmpty) {
        // Add a newline if the speaker changes or if this is a new thought
        if (lastSegment == null || 
            lastSegment.speakerId != segment.speakerId) {
          buffer.write('\n\n');
        } else {
          buffer.write(' ');
        }
      }
      
      // Add speaker tag if requested and available
      if (includeSpeakerTags && segment.speakerId != null) {
        buffer.write('${segment.speakerId}: ');
      }
      
      buffer.write(segment.text);
      lastSegment = segment;
    }
    
    return buffer.toString();
  }
}

class RecognizedSegment {
  final int index;
  String text;
  String? speakerId;
  bool isProcessed;
  double start;
  double end;
  Float32List? speakerEmbedding;

  RecognizedSegment({
    required this.index,
    required this.text,
    this.speakerId,
    this.isProcessed = false,
    required this.start,
    required this.end,
    this.speakerEmbedding,
  });

  // Add a method to convert to/from JSON for persistence
  Map<String, dynamic> toJson() => {
    'index': index,
    'text': text,
    'speakerId': speakerId,
    'isProcessed': isProcessed,
    'start': start,
    'end': end,
  };

  factory RecognizedSegment.fromJson(Map<String, dynamic> json) => RecognizedSegment(
    index: json['index'],
    text: json['text'],
    speakerId: json['speakerId'],
    isProcessed: json['isProcessed'],
    start: json['start'],
    end: json['end'],
  );
}

class AudioSegment {
  final Float32List samples;
  final int sampleRate;
  final int index;
  final double start;
  final double end;
  
  AudioSegment({
    required this.samples,
    required this.sampleRate,
    required this.index,
    required this.start,
    required this.end,
  });
}

class SpeechState extends ChangeNotifier {
  final TextEditingController controller = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();
  
  RecordState recordState = RecordState.stop;
  bool isInitialized = false;
  int currentIndex = 0;
  double currentTimestamp = 0.0;
  int currentSpeakerCount = 0;
  
  // Store all recognized segments
  final List<RecognizedSegment> recognizedSegments = [];

  // First pass - streaming recognition
  sherpa_onnx.OnlineRecognizer? onlineRecognizer;
  sherpa_onnx.OnlineStream? onlineStream;

  // Second pass - offline recognition
  sherpa_onnx.OfflineRecognizer? offlineRecognizer;

  // Speaker identification
  sherpa_onnx.SpeakerEmbeddingExtractor? speakerExtractor;
  sherpa_onnx.SpeakerEmbeddingManager? speakerManager;

  List<Float32List> allAudioSamples = [];
  // Buffer for collecting samples between endpoints
  List<Float32List> currentSegmentSamples = [];
  final int sampleRate = 16000;

  // Store segments that need offline processing
  List<AudioSegment> pendingSegments = [];
  bool isProcessingOffline = false;

  // Path to save the complete audio recording
  String? recordingFilePath;
  
  // Create a Conversation object when recording is stopped
  Conversation? lastConversation;

  Future<void> initialize() async {
    if (!isInitialized) {
      try {
        // init online recognizer
        sherpa_onnx.initBindings();
        onlineRecognizer = await createOnlineRecognizer();
        onlineStream = onlineRecognizer?.createStream();

        // init offline recognizer
        offlineRecognizer = await createOfflineRecognizer();

        // init speaker identification components
        speakerExtractor = await createSpeakerExtractor();
        speakerManager = sherpa_onnx.SpeakerEmbeddingManager(speakerExtractor!.dim);

        isInitialized = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Sherpa initialization failed: $e');
      }
    }
  }

  // Helper method to update the displayed text
  void _updateDisplayText() {
    final buffer = StringBuffer();

    // Debug log
    // debugPrint('Updating display text with ${recognizedSegments.length} segments');

    for (final segment in recognizedSegments) {
      // Debug log
      // debugPrint('Segment ${segment.index}: "${segment.text}" (Speaker: ${segment.speakerId ?? "Unknown"})');
      
      if (segment.text.isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        final prefix = segment.speakerId ?? 'Speaker Unknown';
        buffer.write('$prefix: ${segment.text}');
      }
    }

    // final displayText = buffer.toString();
    // debugPrint('Setting display text: $displayText');
    
    controller.value = TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );

    notifyListeners(); // Make sure UI gets updated
  }

  // Add a new segment of recognized text
  void _addRecognizedSegment(String text, double start) {
    recognizedSegments.add(RecognizedSegment(
      index: currentIndex,
      text: text,
      start: start,
      end: start, // Will be updated when segment ends
    ));

    debugPrint('Added new segment $currentIndex: "$text" (${start.toStringAsFixed(2)}s - ${start.toStringAsFixed(2)}s)');
  }

  // Update an existing segment with improved recognition
  void _updateRecognizedSegment(int index, String newText, {String? speakerId, Float32List? embedding}) {
    final segmentIndex = recognizedSegments.indexWhere((s) => s.index == index);
    if (segmentIndex != -1) {
      if (newText.trim().isNotEmpty) {
        recognizedSegments[segmentIndex].text = newText;
      }
      recognizedSegments[segmentIndex].isProcessed = true;

      if (speakerId != null) {
        recognizedSegments[segmentIndex].speakerId = speakerId;
      }
      
      if (embedding != null) {
        recognizedSegments[segmentIndex].speakerEmbedding = embedding;
      }

      // _updateDisplayText();
    }
  }

  Future<void> processSegmentOffline(AudioSegment segment) async {
    debugPrint('Processing segment ${segment.index} offline (${segment.samples.length} samples)');
    
    if (segment.samples.isEmpty) {
      debugPrint('Empty samples for segment ${segment.index}, skipping');
      return;
    }

    try {
      // Perform offline speech recognition
      final offlineStream = offlineRecognizer!.createStream();
      
      debugPrint('Running offline recognition for segment ${segment.index}');
      offlineStream.acceptWaveform(
        samples: segment.samples,
        sampleRate: segment.sampleRate
      );
      
      offlineRecognizer!.decode(offlineStream);
      final result = offlineRecognizer!.getResult(offlineStream);
      
      debugPrint('Offline recognition result for segment ${segment.index}: "${result.text}"');
      
      // Perform speaker identification
      final speakerStream = speakerExtractor!.createStream();
      
      speakerStream.acceptWaveform(
        samples: segment.samples,
        sampleRate: segment.sampleRate,
      );
      
      speakerStream.inputFinished();
      
      final embedding = speakerExtractor!.compute(speakerStream);
      
      // Search for matching speaker
      final threshold = 0.6; // Adjust threshold as needed
      var speakerId = speakerManager!.search(embedding: embedding, threshold: threshold);
      
      // If no match, register a new speaker
      if (speakerId.isEmpty) {
        currentSpeakerCount++;
        speakerId = 'Speaker $currentSpeakerCount';
        debugPrint('New speaker detected: $speakerId for segment ${segment.index}');
        speakerManager!.add(name: speakerId, embedding: embedding);
      } else {
        debugPrint('Matched existing speaker: $speakerId for segment ${segment.index}');
      }

      // Ignore empty results
      if (result.text.trim().isNotEmpty) {
        // Update the recognized segment with both improved text and speaker ID
        _updateRecognizedSegment(
          segment.index, 
          result.text,
          speakerId: speakerId,
          embedding: embedding,
        );
      } 
      
      // Free resources
      offlineStream.free();
      speakerStream.free();
    } catch (e) {
      debugPrint('Error processing segment ${segment.index} offline: $e');
    }
  }

  Future<void> processPendingSegments() async {
    if (pendingSegments.isEmpty || isProcessingOffline) {
      debugPrint('No pending segments to process or already processing');
      return;
    }
    
    debugPrint('Processing ${pendingSegments.length} pending segments');
    isProcessingOffline = true;
    
    try {
      // Create a local copy to process to avoid modification during iteration
      final segmentsToProcess = List<AudioSegment>.from(pendingSegments);
      pendingSegments.clear();
      
      for (final segment in segmentsToProcess) {
        debugPrint('Processing pending segment ${segment.index}');
        await processSegmentOffline(segment);
        // Update display after each segment is processed
        _updateDisplayText();
      }
    } catch (e) {
      debugPrint('Error processing pending segments: $e');
    } finally {
      isProcessingOffline = false;
      debugPrint('Finished processing pending segments');
    }
  }

  Future<void> toggleRecording() async {
    if (recordState == RecordState.stop) {
      controller.value = TextEditingValue(
        text: "Initializing Yappy!, just a moment..."
      );
      await startRecording();
    } else {
      await stopRecording();
    }
  }

  Future<String> _createRecordingFilePath() async {
    // final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // return '${dir.path}/recording_$timestamp.wav';
    return '/storage/emulated/0/Documents/recording_$timestamp.wav';
  }

  Future<void> startRecording() async {
    if (!isInitialized) {
      await initialize();
    }

    try {
      if (await audioRecorder.hasPermission()) {
        // Reset speakers for new recording
        currentSpeakerCount = 0;
        recognizedSegments.clear();

        // Create a path for saving the recording
        recordingFilePath = await _createRecordingFilePath();

        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );

        final recordStream = await audioRecorder.startStream(config);
        currentSegmentSamples.clear();
        allAudioSamples.clear();
        currentTimestamp = 0.0;
        currentIndex = 0;

        recordState = RecordState.record;
        controller.value = TextEditingValue(
          text: "Listening..."
        );
        notifyListeners();

        recordStream.listen(
          (data) {
            final samplesFloat32 = convertBytesToFloat32(Uint8List.fromList(data));
            
            // Add samples to current segment buffer
            currentSegmentSamples.add(samplesFloat32);
            allAudioSamples.add(samplesFloat32);

            // Update current timestamp based on number of samples
            currentTimestamp += samplesFloat32.length / sampleRate;

            onlineStream!.acceptWaveform(
              samples: samplesFloat32, 
              sampleRate: sampleRate
            );
            
            while (onlineRecognizer!.isReady(onlineStream!)) {
              onlineRecognizer!.decode(onlineStream!);
            }
            
            final text = onlineRecognizer!.getResult(onlineStream!).text;

            if (text.isNotEmpty) {
              // Update or add the current segment
              final existingSegmentIndex = recognizedSegments.indexWhere((s) => s.index == currentIndex);

              if (existingSegmentIndex != -1) {
                // Update existing segment
                recognizedSegments[existingSegmentIndex].text = text;
                // debugPrint('Updated segment $currentIndex with text: "$text"');
              } else {
                // Add new segment
                debugPrint('Adding new segment $currentIndex with text: "$text"');
                _addRecognizedSegment(text, currentTimestamp);
              }
              
              // Always update display when we have new text
              _updateDisplayText();
            }

            if (onlineRecognizer!.isEndpoint(onlineStream!)) {
              // Store the current segment for offline processing

              //ISSUE IS HERE, need to use recognizedSegments.LastOrNull like before, or integrate VAD
              if (currentSegmentSamples.isNotEmpty && recognizedSegments.lastOrNull != null
                ) {
                // Combine all Float32Lists into a single one
                final combinedSamples = Float32List(currentSegmentSamples.fold<int>(
                  0, (sum, list) => sum + list.length));
                var offset = 0;
                for (var samples in currentSegmentSamples) {
                  combinedSamples.setRange(offset, offset + samples.length, samples);
                  offset += samples.length;
                }

                final segmentStart = recognizedSegments.lastOrNull?.start ?? 0.0;

                pendingSegments.add(AudioSegment(
                  samples: combinedSamples,
                  sampleRate: sampleRate,
                  index: currentIndex,
                  start: segmentStart,
                  end: currentTimestamp,
                ));
                
                // Process with online recognizer in the background
                processPendingSegments();
              }
              
              // Reset for next segment
              onlineRecognizer!.reset(onlineStream!);
              currentSegmentSamples.clear();
              currentIndex += 1;
            }
          },
          onError: (error) {
            debugPrint('Error from audio stream: $error');
          },
          onDone: () {
            debugPrint('Audio stream done');
          },
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> saveWavFile() async {
    if (allAudioSamples.isEmpty || recordingFilePath == null) return;
    
    try {
      // Combine all audio samples
      final totalSamples = allAudioSamples.fold<int>(0, (sum, list) => sum + list.length);
      final combinedSamples = Float32List(totalSamples);
      
      var offset = 0;
      for (var samples in allAudioSamples) {
        combinedSamples.setRange(offset, offset + samples.length, samples);
        offset += samples.length;
      }
      
      // Convert Float32List to Int16List for WAV format
      final int16Samples = Int16List(combinedSamples.length);
      for (var i = 0; i < combinedSamples.length; i++) {
        // Scale and clamp to Int16 range
        final scaledSample = combinedSamples[i] * 32767;
        int16Samples[i] = scaledSample.clamp(-32768, 32767).toInt();
      }
      
      // Create WAV file
      final file = File(recordingFilePath!);
      final sink = file.openWrite();
      
      // WAV header (44 bytes)
      final header = ByteData(44);
      
      // RIFF chunk descriptor
      header.setUint8(0, 0x52); // 'R'
      header.setUint8(1, 0x49); // 'I'
      header.setUint8(2, 0x46); // 'F'
      header.setUint8(3, 0x46); // 'F'
      
      // Chunk size (file size - 8)
      final dataSize = int16Samples.length * 2; // 2 bytes per sample
      final fileSize = 36 + dataSize;
      header.setUint32(4, fileSize, Endian.little);
      
      // Format ('WAVE')
      header.setUint8(8, 0x57); // 'W'
      header.setUint8(9, 0x41); // 'A'
      header.setUint8(10, 0x56); // 'V'
      header.setUint8(11, 0x45); // 'E'
      
      // 'fmt ' subchunk
      header.setUint8(12, 0x66); // 'f'
      header.setUint8(13, 0x6D); // 'm'
      header.setUint8(14, 0x74); // 't'
      header.setUint8(15, 0x20); // ' '
      
      // Subchunk1 size (16 for PCM)
      header.setUint32(16, 16, Endian.little);
      
      // Audio format (1 for PCM)
      header.setUint16(20, 1, Endian.little);
      
      // Number of channels (1 for mono)
      header.setUint16(22, 1, Endian.little);
      
      // Sample rate
      header.setUint32(24, sampleRate, Endian.little);
      
      // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
      header.setUint32(28, sampleRate * 1 * 16 ~/ 8, Endian.little);
      
      // Block align (NumChannels * BitsPerSample/8)
      header.setUint16(32, 1 * 16 ~/ 8, Endian.little);
      
      // Bits per sample
      header.setUint16(34, 16, Endian.little);
      
      // 'data' subchunk
      header.setUint8(36, 0x64); // 'd'
      header.setUint8(37, 0x61); // 'a'
      header.setUint8(38, 0x74); // 't'
      header.setUint8(39, 0x61); // 'a'
      
      // Subchunk2 size (data size)
      header.setUint32(40, dataSize, Endian.little);
      
      // Write header
      sink.add(header.buffer.asUint8List());
      
      // Write data
      final dataBytes = int16Samples.buffer.asUint8List();
      sink.add(dataBytes);
      
      await sink.close();
      
      debugPrint('WAV file saved to: $recordingFilePath');
    } catch (e) {
      debugPrint('Error saving WAV file: $e');
    }
  }

  Future<Conversation> createConversation() async {
    // Ensure WAV file is saved
    await saveWavFile();
    
    // Create conversation object
    return Conversation(
      segments: List.from(recognizedSegments), // Make a copy
      audioFilePath: recordingFilePath ?? '',
    );
  }

  Future<void> stopRecording() async {
    debugPrint('Stopping recording');

    try {
      // Update UI immediately to show we're stopping
      recordState = RecordState.stop;
      notifyListeners();

      // Process any remaining audio
      if (currentSegmentSamples.isNotEmpty) {
        debugPrint('Processing final segment $currentIndex');

        // Combine all Float32Lists into a single one
        final combinedSamples = Float32List(currentSegmentSamples.fold<int>(
          0, (sum, list) => sum + list.length));
        var offset = 0;
        for (var samples in currentSegmentSamples) {
          combinedSamples.setRange(offset, offset + samples.length, samples);
          offset += samples.length;
        }

        final segmentStart = recognizedSegments.lastOrNull?.start ?? 0.0;

        pendingSegments.add(AudioSegment(
          samples: combinedSamples,
          sampleRate: sampleRate,
          index: currentIndex,
          start: segmentStart,
          end: currentTimestamp,
        ));
      }

      // Clean up resources
      if (onlineStream != null) {
        onlineStream!.free();
        onlineStream = onlineRecognizer?.createStream();
      }
      
      await audioRecorder.stop();

      // Process final segments
      debugPrint('Processing final segments with offline recognizer');
      await processPendingSegments();

      // Save the recording as a WAV file
      debugPrint('Saving WAV file');
      await saveWavFile();
    
      // Create conversation object
      debugPrint('Creating conversation object');
      lastConversation = await createConversation();

      currentSegmentSamples.clear();
      // allAudioSamples.clear();
      // Final update to display text
      _updateDisplayText();
      
      debugPrint('Recording stopped successfully');
    } catch (e) {
<<<<<<< HEAD
      debugPrint('Error stopping recording: $e'); 
=======
      debugPrint('Error stopping recording: $e');
>>>>>>> developer
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    audioRecorder.dispose();
    onlineStream?.free();
    onlineRecognizer?.free();
    offlineRecognizer?.free();
    speakerExtractor?.free();
    speakerManager?.free();
    super.dispose();
  }
<<<<<<< HEAD

  getRecordedText() {
    if (lastConversation != null) {
      return lastConversation!.getTranscript();
    } else {
      return "No recording available.";
    }




  }
=======
>>>>>>> developer
}
