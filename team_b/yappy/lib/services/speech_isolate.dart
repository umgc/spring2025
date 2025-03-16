import 'dart:isolate';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

// Message to be sent to the isolate
class ProcessSegmentMessage {
  final Float32List samples;
  final int sampleRate;
  final int segmentIndex;
  final Map<String, dynamic> recognizerConfigs;

  ProcessSegmentMessage({
    required this.samples,
    required this.sampleRate,
    required this.segmentIndex,
    required this.recognizerConfigs,
  });
}

// Response from the isolate
class ProcessSegmentResult {
  final int segmentIndex;
  final String text;
  final String speakerId;
  final Float32List? embedding;
  final bool success;
  final String? error;

  ProcessSegmentResult({
    required this.segmentIndex,
    required this.text,
    required this.speakerId,
    this.embedding,
    required this.success,
    this.error,
  });
}

class SpeechProcessingIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _receivePort = ReceivePort();
  final _responseCompleter = Completer<SendPort>();
  
  // Stream controller for receiving results
  final _resultController = StreamController<ProcessSegmentResult>.broadcast();
  Stream<ProcessSegmentResult> get results => _resultController.stream;
  
  // Initialize the isolate and recognizers
  Future<void> initialize(Map<String, dynamic> configs) async {
    // Check if already initialized
    if (_isolate != null) return;
    
    // Start the isolate
    _isolate = await Isolate.spawn(
      _isolateEntry, 
      [_receivePort.sendPort, configs]
    );
    
    // Set up communication
    _receivePort.listen((message) {
      if (message is SendPort) {
        // First message is the SendPort for communicating with the isolate
        _sendPort = message;
        _responseCompleter.complete(message);
      } else if (message is ProcessSegmentResult) {
        // Subsequent messages are results from the isolate
        _resultController.add(message);
      }
    });
    
    // Wait until communication is established
    await _responseCompleter.future;
  }

  // Process a segment asynchronously
  Future<void> processSegment(ProcessSegmentMessage message) async {
    if (_sendPort == null) {
      throw Exception('Isolate not initialized');
    }
    
    // Send the message to isolate
    _sendPort!.send(message);
  }

  // Dispose resources
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _receivePort.close();
    _resultController.close();
  }

  // Static entry point for the isolate
  static void _isolateEntry(List<dynamic> args) {
    final SendPort sendPort = args[0];
    final configs = args[1] as Map<String, dynamic>;
    
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    
    // Initialize recognizers
    sherpa_onnx.initBindings();
    sherpa_onnx.OfflineRecognizer? offlineRecognizer;
    sherpa_onnx.SpeakerEmbeddingExtractor? speakerExtractor;
    sherpa_onnx.SpeakerEmbeddingManager? speakerManager;
    
    _initializeRecognizers(configs).then((initialized) {
      if (initialized != null) {
        offlineRecognizer = initialized['offlineRecognizer'];
        speakerExtractor = initialized['speakerExtractor'];
        speakerManager = initialized['speakerManager'];
        
        receivePort.listen((message) {
          if (message is ProcessSegmentMessage) {
            _processSegment(
              message, 
              offlineRecognizer!, 
              speakerExtractor!, 
              speakerManager!,
              sendPort
            );
          }
        });
      }
    });
  }
  
  // Initialize recognizers inside the isolate
  static Future<Map<String, dynamic>?> _initializeRecognizers(Map<String, dynamic> configs) async {
    try {
      // Create offline recognizer
      final offlineConfig = sherpa_onnx.OfflineRecognizerConfig(
        model: configs['offlineModelConfig']
      );
      final offlineRecognizer = sherpa_onnx.OfflineRecognizer(offlineConfig);
      
      // Create speaker extractor
      final speakerConfig = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
        model: configs['speakerModel'],
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      );
      final speakerExtractor = sherpa_onnx.SpeakerEmbeddingExtractor(config: speakerConfig);
      
      // Create speaker manager
      final speakerManager = sherpa_onnx.SpeakerEmbeddingManager(speakerExtractor.dim);
      
      return {
        'offlineRecognizer': offlineRecognizer,
        'speakerExtractor': speakerExtractor,
        'speakerManager': speakerManager,
      };
    } catch (e) {
      debugPrint('Error initializing recognizers in isolate: $e');
      return null;
    }
  }
  
  // Process a segment inside the isolate
  static Future<void> _processSegment(
    ProcessSegmentMessage message,
    sherpa_onnx.OfflineRecognizer offlineRecognizer,
    sherpa_onnx.SpeakerEmbeddingExtractor speakerExtractor,
    sherpa_onnx.SpeakerEmbeddingManager speakerManager,
    SendPort sendPort
  ) async {
    try {
      debugPrint('Isolate: Processing segment ${message.segmentIndex} (${message.samples.length} samples)');
      
      if (message.samples.isEmpty) {
        sendPort.send(ProcessSegmentResult(
          segmentIndex: message.segmentIndex,
          text: '',
          speakerId: '',
          success: false,
          error: 'Empty samples',
        ));
        return;
      }
      
      // Perform offline speech recognition
      final offlineStream = offlineRecognizer.createStream();
      offlineStream.acceptWaveform(
        samples: message.samples,
        sampleRate: message.sampleRate
      );
      
      offlineRecognizer.decode(offlineStream);
      final result = offlineRecognizer.getResult(offlineStream);
      
      debugPrint('Isolate: Recognition result: "${result.text}"');
      
      // Speaker identification
      final speakerStream = speakerExtractor.createStream();
      speakerStream.acceptWaveform(
        samples: message.samples,
        sampleRate: message.sampleRate,
      );
      
      speakerStream.inputFinished();
      final embedding = speakerExtractor.compute(speakerStream);
      
      // Search for matching speaker
      final threshold = 0.6;
      var speakerId = speakerManager.search(embedding: embedding, threshold: threshold);
      
      // If no match, register a new speaker
      if (speakerId.isEmpty) {
        speakerId = 'Speaker ${message.recognizerConfigs['nextSpeakerId']}';
        debugPrint('Isolate: New speaker detected: $speakerId');
        speakerManager.add(name: speakerId, embedding: embedding);
      } else {
        debugPrint('Isolate: Matched existing speaker: $speakerId');
      }
      
      // Send the result back
      sendPort.send(ProcessSegmentResult(
        segmentIndex: message.segmentIndex,
        text: result.text,
        speakerId: speakerId,
        embedding: embedding,
        success: true,
      ));
      
      // Clean up
      offlineStream.free();
      speakerStream.free();
    } catch (e) {
      debugPrint('Isolate: Error processing segment: $e');
      sendPort.send(ProcessSegmentResult(
        segmentIndex: message.segmentIndex,
        text: '',
        speakerId: '',
        success: false,
        error: e.toString(),
      ));
    }
  }
}