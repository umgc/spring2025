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
  final int? newSpeakerCount;

  ProcessSegmentResult({
    required this.segmentIndex,
    required this.text,
    required this.speakerId,
    this.embedding,
    required this.success,
    this.error,
    this.newSpeakerCount,
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
  
  // Keep track of speaker count locally in the isolate handler
  int _currentSpeakerCount = 0;
  
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
        
        // Debug the speaker ID
        debugPrint("Received result from isolate - Speaker ID: ${message.speakerId}, Count: ${message.newSpeakerCount}");
        
        // Update local speaker count if needed
        if (message.newSpeakerCount != null && message.newSpeakerCount! > _currentSpeakerCount) {
          _currentSpeakerCount = message.newSpeakerCount!;
          debugPrint("Updated local speaker count to: $_currentSpeakerCount");
        }
        
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
    
    // Update our local copy of speaker count if the incoming count is higher
    if (message.recognizerConfigs['currentSpeakerCount'] != null) {
      int incomingSpeakerCount = message.recognizerConfigs['currentSpeakerCount'];
      if (incomingSpeakerCount > _currentSpeakerCount) {
        _currentSpeakerCount = incomingSpeakerCount;
        debugPrint("Updated isolate speaker count to: $_currentSpeakerCount");
      }
    }
    
    // Send the message to isolate with updated speaker count
    final updatedMessage = ProcessSegmentMessage(
      samples: message.samples,
      sampleRate: message.sampleRate,
      segmentIndex: message.segmentIndex,
      recognizerConfigs: {
        ...message.recognizerConfigs,
        'currentSpeakerCount': _currentSpeakerCount,
      },
    );
    
    _sendPort!.send(updatedMessage);
  }
  
  // Update the speaker count (call this when a new speaker is detected in the main thread)
  void updateSpeakerCount(int count) {
    if (count > _currentSpeakerCount) {
      _currentSpeakerCount = count;
      debugPrint("Manually updated isolate speaker count to: $_currentSpeakerCount");
    }
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
    
    // Track speaker count inside the isolate
    int isolateSpeakerCount = 0;
    
    _initializeRecognizers(configs).then((initialized) {
      if (initialized != null) {
        offlineRecognizer = initialized['offlineRecognizer'];
        speakerExtractor = initialized['speakerExtractor'];
        speakerManager = initialized['speakerManager'];
        
        receivePort.listen((message) {
          if (message is ProcessSegmentMessage) {
            // Update speaker count from message if available
            if (message.recognizerConfigs['currentSpeakerCount'] != null) {
              int msgCount = message.recognizerConfigs['currentSpeakerCount'];
              if (msgCount > isolateSpeakerCount) {
                isolateSpeakerCount = msgCount;
                debugPrint("Isolate updated count to: $isolateSpeakerCount");
              }
            }
            
            _processSegment(
              message, 
              offlineRecognizer!, 
              speakerExtractor!, 
              speakerManager!,
              sendPort,
              isolateSpeakerCount,
              (newCount) {
                isolateSpeakerCount = newCount;
                debugPrint("Callback updated isolate count to: $isolateSpeakerCount");
              }
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
    SendPort sendPort,
    int currentSpeakerCount,
    Function(int) updateSpeakerCount
  ) async {
    try {
      debugPrint('Isolate: Processing segment ${message.segmentIndex} (${message.samples.length} samples)');
      
      if (message.samples.isEmpty) {
        sendPort.send(ProcessSegmentResult(
          segmentIndex: message.segmentIndex,
          text: '',
          speakerId: 'Unknown',
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
      
      // Skip speaker identification if result is empty
      if (result.text.trim().isEmpty || result.text.trim().startsWith(RegExp(r'[\[\(]'))) {
        sendPort.send(ProcessSegmentResult(
          segmentIndex: message.segmentIndex,
          text: result.text,
          speakerId: 'Unknown',
          success: true,
        ));
        
        offlineStream.free();
        return;
      }
      
      // Speaker identification
      final speakerStream = speakerExtractor.createStream();
      speakerStream.acceptWaveform(
        samples: message.samples,
        sampleRate: message.sampleRate,
      );
      
      speakerStream.inputFinished();
      final embedding = speakerExtractor.compute(speakerStream);
      
      // Search for matching speaker
      // Adjust threshold lower for better accuracy
      final threshold = 0.2;
      var speakerId = speakerManager.search(embedding: embedding, threshold: threshold);
      
      int newSpeakerCount = currentSpeakerCount;
      
      // If no match, register a new speaker
      if (speakerId.isEmpty) {
        // Increment speaker count for the new speaker
        newSpeakerCount = currentSpeakerCount + 1;
        
        speakerId = 'Speaker $newSpeakerCount';
        debugPrint('Isolate: New speaker detected: $speakerId (count: $newSpeakerCount)');
        speakerManager.add(name: speakerId, embedding: embedding);
        
        // Update the callback
        updateSpeakerCount(newSpeakerCount);
      } else {
        debugPrint('Isolate: Matched existing speaker: $speakerId');
      }
      
      // Send the result back with updated speaker count
      sendPort.send(ProcessSegmentResult(
        segmentIndex: message.segmentIndex,
        text: result.text,
        speakerId: speakerId,
        embedding: embedding,
        success: true,
        newSpeakerCount: newSpeakerCount,
      ));
      
      // Clean up
      offlineStream.free();
      speakerStream.free();
    } catch (e) {
      debugPrint('Isolate: Error processing segment: $e');
      sendPort.send(ProcessSegmentResult(
        segmentIndex: message.segmentIndex,
        text: '',
        speakerId: 'Unknown',
        success: false,
        error: e.toString(),
      ));
    }
  }
}