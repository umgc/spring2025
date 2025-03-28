import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import '../main.dart';
import 'utils.dart';
import 'online_model.dart';
import 'offline_model.dart';
import 'speaker_model.dart';
import 'vad_model.dart';
import 'speech_isolate.dart';
import 'package:aws_common/aws_common.dart';
import 'client.dart';
import 'models.dart';
import 'transcription.dart';

Future<sherpa_onnx.OnlineRecognizer> createOnlineRecognizer() async {
  final type = 0;

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

Future<sherpa_onnx.VoiceActivityDetector> createVoiceActivityDetector() async {
  final type = 0;

  final model = await getVadModel(type: type);
  final sileroConfig = sherpa_onnx.SileroVadModelConfig(
    model: model,
    threshold: 0.5,
    minSilenceDuration: 0.25,
    minSpeechDuration: 0.1,
    windowSize: 512,
    maxSpeechDuration: 10.0,
  );
    
  final vadConfig = sherpa_onnx.VadModelConfig(
    sileroVad: sileroConfig,
    numThreads: 2,
    provider: 'cpu',
    debug: false,
  );

  return sherpa_onnx.VoiceActivityDetector(config: vadConfig, bufferSizeInSeconds: 10);
}

class Conversation {
  final List<RecognizedSegment> segments;
  final String audioFilePath;
  String awsTranscription = '';

  Conversation({
    required this.segments,
    required this.audioFilePath,
    this.awsTranscription = '',
  });
  
  // Update JSON methods
  Map<String, dynamic> toJson() => {
    'segments': segments.map((s) => s.toJson()).toList(),
    'audioFilePath': audioFilePath,
    'awsTranscription': awsTranscription,
  };
  
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    segments: (json['segments'] as List)
        .map((s) => RecognizedSegment.fromJson(s))
        .toList(),
    audioFilePath: json['audioFilePath'],
    awsTranscription: json['awsTranscription'] ?? '',
  );
  
  String getTranscript({bool includeSpeakerTags = true}) {
    final buffer = StringBuffer();
    RecognizedSegment? lastSegment;
    
    for (final segment in segments) {
      if (segment.text.isEmpty) continue;
      
      if (buffer.isNotEmpty) {
        if (lastSegment == null || lastSegment.speakerId != segment.speakerId) {
          buffer.write('\n\n');
        } else {
          buffer.write('\n');
        }
      }
      
      if (includeSpeakerTags && segment.speakerId != null) {
        buffer.write('${segment.speakerId}: ');
      }
      
      buffer.write(segment.text);
      lastSegment = segment;
    }
    
    return buffer.toString();
  }
  
  String getAwsTranscript() {
    return awsTranscription;
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
  TranscribeStreamingClient? awsClient;
  StreamSink<Uint8List>? awsAudioStreamSink;
  StreamSubscription<String>? awsTranscriptSubscription;
  String currentAwsTranscript = '';
  bool isAwsTranscribing = false;
  StringBuffer awsTranscriptBuffer = StringBuffer();

  final TextEditingController controller = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();

  ValueNotifier<List<int>> audioSamplesNotifier = ValueNotifier<List<int>>([]);

  RecordState recordState = RecordState.stop;
  bool isInitialized = false;
  int currentIndex = 0;
  double currentTimestamp = 0.0;
  int currentSpeakerCount = 0;
  
  void updateAudioSamples(List<int> newSamples) {
    audioSamplesNotifier.value = newSamples;
  }
  // Store all recognized segments
  final List<RecognizedSegment> recognizedSegments = [];

  // First pass - streaming recognition
  sherpa_onnx.OnlineRecognizer? onlineRecognizer;
  sherpa_onnx.OnlineStream? onlineStream;

  // Second pass - offline processing
  SpeechProcessingIsolate? speechIsolate;

  // Voice Activity Detector
  sherpa_onnx.VoiceActivityDetector? vad;

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

        // init vad
        vad = await createVoiceActivityDetector();

        // Initialize the isolate with configuration
        speechIsolate = SpeechProcessingIsolate();
        final offlineModelConfig = await getOfflineModelConfig(type: 0);
        final speakerModel = await getSpeakerModel(type: 0);
        
        await speechIsolate?.initialize({
          'offlineModelConfig': offlineModelConfig,
          'speakerModel': speakerModel,
        });

        // Set up listener for results from the isolate
        speechIsolate?.results.listen((result) {
          debugPrint("Received result from isolate: ${result.segmentIndex}, Speaker: ${result.speakerId}");
          
          // Update speaker count if a new speaker was detected
          if (result.newSpeakerCount != null && result.newSpeakerCount! > currentSpeakerCount) {
            currentSpeakerCount = result.newSpeakerCount!;
            debugPrint('Updated main thread speaker count to: $currentSpeakerCount');
          }
          
          // Ignore empty results
          if (result.success && result.text.trim().isNotEmpty) {
            // Make sure speakerId is not null or empty
            String speakerId = result.speakerId;
            if (speakerId.isEmpty) {
              speakerId = 'Speaker Unknown';
            }
            
            _updateRecognizedSegment(
              result.segmentIndex,
              result.text,
              speakerId: speakerId,
              embedding: result.embedding,
            );
            _updateDisplayText();
          }
        });

        isInitialized = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Sherpa initialization failed: $e');
      }
    }
  }

  // Initialize AWS credentials and client
  Future<void> initializeAwsClient() async {
    if (awsClient == null) {
      try {
        // Use StaticCredentialsProvider for simplicity
        // In production, consider using more secure credential providers
        final credentialsProvider = StaticCredentialsProvider(
          AWSCredentials(
            preferences.getString('aws_access_key')!,  // Replace with your idkey
            preferences.getString('aws_secret_key')!   // Replace with your secretkey
          ),
        );
        
        // Create AWS Transcribe client
        awsClient = TranscribeStreamingClient(
          region: preferences.getString('aws_region')!,  // Replace with your AWS region
          credentialsProvider: credentialsProvider,
        );
        
        await preferences.setBool('is_aws_available', true);
        debugPrint('🚣 AWS Transcribe client initialized');
      } catch (e) {
        await preferences.setBool('is_aws_available', false);
        debugPrint('🚣 Error initializing AWS client: $e');
      }
    }
  }
  
  // Start AWS transcription
  Future<void> startAwsTranscription() async {
    if (awsClient == null) {
      await initializeAwsClient();
    }
    
    try {
      isAwsTranscribing = true;
      currentAwsTranscript = '';
      awsTranscriptBuffer.clear();
      
      // Create request with proper parameters
      final request = StartStreamTranscriptionRequest(
        languageCode: LanguageCode.enUs,
        mediaSampleRateHertz: sampleRate,
        mediaEncoding: MediaEncoding.pcm,
        showSpeakerLabel: true,
        // Disable partial results stabilization for better accuracy
        enablePartialResultsStabilization: false,
      );
      
      debugPrint('🚣 Starting AWS transcription with sample rate $sampleRate');
      
      // Start streaming
      final (response, sink, stream) = await awsClient!.startStreamTranscription(request);
      awsAudioStreamSink = sink;
      
      // Create a transformer that converts TranscriptEvent to String
      final stringStream = stream.transform(
        StreamTransformer<TranscriptEvent, String>.fromHandlers(
          handleData: (event, sink) {
            if (event.transcript != null) {
              try {
                final transcript = _processTranscriptEvent(event);
                if (transcript.isNotEmpty) {
                  sink.add(transcript);
                }
              } catch (e) {
                debugPrint('🚣 Error processing transcript: $e');
              }
            }
          },
          handleError: (error, stackTrace, sink) {
            debugPrint('🚣 AWS Transcription Stream Error: $error');
            sink.addError(error, stackTrace);
          },
          handleDone: (sink) {
            debugPrint('🚣 AWS Transcription Stream Done');
            sink.close();
          },
        )
      );
      
      awsTranscriptSubscription = stringStream.listen(
        (transcriptText) {
          if (transcriptText.isNotEmpty) {
            currentAwsTranscript = transcriptText;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('🚣 AWS Transcription Error: $error');
        },
        onDone: () {
          debugPrint('🚣 AWS Transcription Stream Done');
          isAwsTranscribing = false;
          notifyListeners();
        },
      );
      
      debugPrint('🚣 AWS Transcription Started: ${response.sessionId}');
    } catch (e) {
      debugPrint('🚣 Error starting AWS transcription: $e');
      isAwsTranscribing = false;
    }
  }

  // Helper method to process transcript events
  String _processTranscriptEvent(TranscriptEvent event) {
    if (event.transcript?.results == null || event.transcript!.results!.isEmpty) {
      return currentAwsTranscript; // Return current to avoid clearing it
    }
    
    final StringBuffer buffer = StringBuffer();
    bool hasNewCompletedSegments = false;
    
    for (final result in event.transcript!.results!) {
      // Only process complete (non-partial) segments
      if (result.isPartial == false && 
          result.alternatives != null && 
          result.alternatives!.isNotEmpty) {
        
        hasNewCompletedSegments = true;
        final alternative = result.alternatives!.first;
        
        // Get speaker information if available
        String? speaker;
        if (alternative.items != null && alternative.items!.isNotEmpty) {
          for (final item in alternative.items!) {
            if (item.speaker != null && item.speaker!.isNotEmpty) {
              final speakerId = int.tryParse(item.speaker!) ?? 0;
              speaker = "Speaker ${speakerId + 1}";
              break;
            }
          }
        } else if (result.channelId != null) {
          speaker = "Channel ${result.channelId}";
        }
        
        // Add transcript with speaker label
        if (speaker != null && alternative.transcript != null) {
          buffer.write('\n$speaker: ${alternative.transcript}');
        } else if (alternative.transcript != null) {
          buffer.write('\n${alternative.transcript}');
        }
      }
    }
    
    // Only update the transcript if we have new completed segments
    if (hasNewCompletedSegments) {
      // If we already have content, append to it
      if (currentAwsTranscript.isNotEmpty) {
        return currentAwsTranscript + buffer.toString();
      }
      return buffer.toString().trim();
    }
    
    return currentAwsTranscript;
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
        // Make sure we have a speaker ID display string
        final prefix = (segment.speakerId != null && segment.speakerId!.isNotEmpty) 
            ? segment.speakerId! 
            : 'Speaker Unknown';
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

      // Make sure speakerId is not null or empty
      if (speakerId != null && speakerId.isNotEmpty) {
        recognizedSegments[segmentIndex].speakerId = speakerId;
        debugPrint('Updated segment $index with speaker: $speakerId');
      }
      
      if (embedding != null) {
        recognizedSegments[segmentIndex].speakerEmbedding = embedding;
      }

      // _updateDisplayText();
    }
  }

  // Replace the processSegmentOffline method with this version
  Future<void> processSegmentOffline(AudioSegment segment) async {
    debugPrint('Processing segment ${segment.index} offline (${segment.samples.length} samples)');
    
    if (segment.samples.isEmpty) {
      debugPrint('Empty samples for segment ${segment.index}, skipping');
      return;
    }

    try {
      if (speechIsolate == null) {
        debugPrint('Speech isolate not initialized, failing silently');
        return;
      }
      
      // Debug current speaker count
      debugPrint('Sending segment with current speaker count: $currentSpeakerCount');
      
      // Use the isolate to process this segment
      await speechIsolate!.processSegment(ProcessSegmentMessage(
        samples: segment.samples,
        sampleRate: sampleRate,
        segmentIndex: segment.index,
        recognizerConfigs: {
          'currentSpeakerCount': currentSpeakerCount,
        },
      ));
      
      // Processing will continue asynchronously, and results will be handled by the listener
      
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
        // Reset for new recording
        currentSpeakerCount = 0;
        recognizedSegments.clear();
        recordingFilePath = await _createRecordingFilePath();

        // Start AWS transcription in parallel
        await startAwsTranscription();

        const config = RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        );

        final recordStream = await audioRecorder.startStream(config);
        allAudioSamples.clear();
        currentTimestamp = 0.0;
        currentIndex = 0;
        
        // State tracking variables
        bool isCurrentlySpeaking = false;
        double speechStartTime = 0.0;
        currentSegmentSamples.clear();

        recordState = RecordState.record;
        controller.value = TextEditingValue(text: "Listening...");
        notifyListeners();

        recordStream.listen(
          (data) {
            // Send to AWS
            if (isAwsTranscribing && awsAudioStreamSink != null) {
              try {
                awsAudioStreamSink!.add(Uint8List.fromList(data));
              } catch (e) {
                debugPrint('🚣 Error sending audio to AWS: $e');
              }
            }

            final samplesFloat32 = convertBytesToFloat32(Uint8List.fromList(data));
            
            // Always add to complete recording and update timestamp
            allAudioSamples.add(samplesFloat32);
            currentTimestamp += samplesFloat32.length / sampleRate;
            
            // Update audio visualization
            audioSamplesNotifier.value = samplesFloat32
                .map((e) => (e * 100000).toInt())
                .toList();

            // Process audio through VAD
            final windowSize = vad!.config.sileroVad.windowSize;
            int offset = 0;
            while (offset + windowSize <= samplesFloat32.length) {
              final windowBuffer = Float32List.sublistView(samplesFloat32, offset, offset + windowSize);
              vad!.acceptWaveform(windowBuffer);
              offset += windowSize;
            }
            
            // Check current VAD state
            bool speechDetected = vad!.isDetected();
            
            // TRANSITION: Silence → Speech (START COLLECTING)
            if (!isCurrentlySpeaking && speechDetected) {
              debugPrint('🎙️ Speech started at: $currentTimestamp');
              isCurrentlySpeaking = true;
              speechStartTime = currentTimestamp;
              currentSegmentSamples.clear(); // Start fresh collection
              
              // Reset the recognizer for a new segment
              onlineRecognizer!.reset(onlineStream!);
            }
            
            // DURING SPEECH: Collect and process audio
            if (isCurrentlySpeaking) {
              // Add samples to the current segment
              currentSegmentSamples.add(samplesFloat32);
              
              // Process with online recognizer for real-time feedback
              onlineStream!.acceptWaveform(
                samples: samplesFloat32, 
                sampleRate: sampleRate
              );
              
              while (onlineRecognizer!.isReady(onlineStream!)) {
                onlineRecognizer!.decode(onlineStream!);
              }
              
              final text = onlineRecognizer!.getResult(onlineStream!).text;
              
              // Update display with current recognition
              final existingSegmentIndex = recognizedSegments.indexWhere((s) => s.index == currentIndex);

              if (existingSegmentIndex != -1) {
                // Update existing segment
                debugPrint('Updated segment #$currentIndex of ${recognizedSegments.length}');
                recognizedSegments[existingSegmentIndex].text = text.isEmpty ? recognizedSegments[existingSegmentIndex].text : text;
              } else {
                // Add new segment
                debugPrint('Adding new segment $currentIndex with text: "$text"');
                _addRecognizedSegment(text, speechStartTime);
              }
              
              _updateDisplayText();
            }
            
            // TRANSITION: Speech → Silence (SAVE SEGMENT & STOP COLLECTING)
            if (isCurrentlySpeaking && !speechDetected) {
              debugPrint('🔇 Speech ended at: $currentTimestamp, duration: ${currentTimestamp - speechStartTime}');
              isCurrentlySpeaking = false;
              
              // Create and add a new audio segment for background processing
              pendingSegments.add(AudioSegment(
                samples: vad!.front().samples,
                sampleRate: sampleRate,
                index: currentIndex,
                start: speechStartTime,
                end: currentTimestamp,
              ));
              
              // Process with offline recognizer in the background
              processPendingSegments();
              
              // Increment for next segment
              currentIndex += 1;

              // Clear current segment samples
              vad!.pop();
              
              // During silence we don't collect samples - they're effectively discarded
              // until the next speech segment begins
            }

            // Process any complete segments from VAD
            while (!vad!.isEmpty()) {
              final segment = vad!.front();
              debugPrint('💬 VAD segment at: ${segment.start / sampleRate}s - ${currentTimestamp}s');
              vad!.pop();
            }
          },
          onError: (error) {
            debugPrint('Error from audio stream: $error');
          },
          onDone: () {
            debugPrint('🫳🎤 Audio stream done; ${recognizedSegments.length} segments with $currentSpeakerCount speakers');
            // Clear VAD buffer - flush any pending segments
            vad?.flush();
            awsAudioStreamSink?.close();
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
    debugPrint('Saving WAV file');
    await saveWavFile();
    
    // Create conversation object
    return Conversation(
      segments: List.from(recognizedSegments), // Make a copy
      audioFilePath: recordingFilePath ?? '',
      awsTranscription: currentAwsTranscript,
    );
  }

  // Properly stop AWS transcription
  Future<void> stopAwsTranscription() async {
    if (isAwsTranscribing) {
      try {
        // Close the audio sink to indicate end of stream
        await awsAudioStreamSink?.close();
        
        // Give AWS a moment to process final audio
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Then cancel the subscription
        await awsTranscriptSubscription?.cancel();
      } catch (e) {
        debugPrint('🚣 Error stopping AWS transcription: $e');
      } finally {
        isAwsTranscribing = false;
        awsAudioStreamSink = null;
        awsTranscriptSubscription = null;
      }
    }
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

      // Stop AWS transcription properly
      await stopAwsTranscription();

      // Process final segments
      debugPrint('Processing final segments with offline recognizer');
      await processPendingSegments();
   
      // Create conversation object (also saves the WAV file)
      debugPrint('Creating conversation object');
      lastConversation = await createConversation();

      currentSegmentSamples.clear();

      _updateDisplayText();
      
      debugPrint('Recording stopped successfully');
    } catch (e) {
      debugPrint('Error stopping recording: $e');
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
    vad?.free();
    speechIsolate?.dispose();
    super.dispose();
  }

  // Add method to get AWS transcription
  String getAwsRecordedText() {
    if (lastConversation != null) {
      return lastConversation!.getAwsTranscript();
    } else {
      return "No AWS transcription available.";
    }
  }

  getRecordedText() {
    if (lastConversation != null) {
      return lastConversation!.getTranscript();
    } else {
      return "No recording available.";
    }
  }
}

// /// Custom transcription strategy that builds a final transcript with speaker labels
// class CustomTranscriptionStrategy implements TranscriptionBuildingStrategy {
//   @override
//   String buildTranscription(Iterable<Result> results) {
//     final buffer = StringBuffer();
    
//     // Filter out partial results, we only want complete segments
//     final completeResults = results.where((result) => result.isPartial == false).toList();
    
//     // Sort by start time to maintain chronological order
//     completeResults.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));
    
//     // Process each complete result
//     for (final result in completeResults) {
//       if (result.alternatives == null || result.alternatives!.isEmpty) continue;
      
//       final alternative = result.alternatives!.first;
//       if (alternative.transcript == null || alternative.transcript!.isEmpty) continue;
      
//       // Add speaker information if available
//       if (result.channelId != null) {
//         buffer.write('\nChannel ${result.channelId}: ${alternative.transcript}');
//       } else {
//         // Check for speaker labels in items
//         String? speaker;
//         if (alternative.items != null && alternative.items!.isNotEmpty) {
//           for (final item in alternative.items!) {
//             if (item.speaker != null && item.speaker!.isNotEmpty) {
//               final speakerId = int.tryParse(item.speaker!) ?? 0;
//               speaker = "Speaker ${speakerId + 1}";
//               break;
//             }
//           }
//         }
        
//         if (speaker != null) {
//           buffer.write('\n$speaker: ${alternative.transcript}');
//         } else {
//           buffer.write('\n${alternative.transcript}');
//         }
//       }
//     }
    
//     return buffer.toString().trim();
//   }
// }