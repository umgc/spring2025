import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:yappy/services/file_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'database_helper.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockDatabaseHelper mockDbHelper;
  late FileHandler fileHandler;
  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  // I have to cache the temp directory path as multiple calls 
  // to getApplicationDocumentsDirectory() return different paths
  late String tempDirectoryPath; 

  setUpAll(() async {
    // Register the path_provider plugin
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          final directory = Directory.systemTemp.createTempSync();
          tempDirectoryPath = directory.path;
          return tempDirectoryPath;
        }
        return null;
      }
    );

    // Initialize the database
    mockDbHelper = MockDatabaseHelper();
    fileHandler = FileHandler();
  });

  group('FileHandler', () {
    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      fileHandler = FileHandler();
    });

    test('should save transcript text data to local storage', () async {
      int transcriptId = 1; // Assuming transcriptId 1 exists in the database with test data
      Map<String, String> mockTranscriptData = {
        'transcript_text_data': 'Sample text',
        'industry': 'Sample industry',
      };

      when(mockDbHelper.getTranscriptTextDataAndIndustryById(transcriptId))
          .thenAnswer((_) async => mockTranscriptData);

      await fileHandler.saveTranscriptTextToLocal(mockDbHelper, transcriptId);
      final directory = tempDirectoryPath;
      final fileName = 'transcript_text_${transcriptId}_Sample industry.txt';
      final file = File('$directory/$fileName');

      expect(await file.exists(), isTrue);
    });

    test('should move file from local storage to database', () async {
      int transcriptId = 1; // Assuming transcriptId 1 exists in the database with test data
      final fileName = 'transcript_text_${transcriptId}_Vehicle Maintenance.txt';
      final directory = await fileHandler.localStoragePath;
      final file = File('$directory/$fileName');

      // Setup: Create the file in local storage
      await file.writeAsString('Test content for transcript text');

      if (await file.exists()) {
        final fileBytes = await file.readAsBytes();
        when(mockDbHelper.updateTranscriptDocument(transcriptId, fileBytes))
            .thenAnswer((_) async => true);
        when(mockDbHelper.getTranscriptById(transcriptId))
            .thenAnswer((_) async => {
                  'transcript_id': transcriptId,
                  'transcript_document': fileBytes,
                });

        await mockDbHelper.updateTranscriptDocument(transcriptId, fileBytes);

        final transcript = await mockDbHelper.getTranscriptById(transcriptId);
        expect(transcript, isNotNull);
        expect(transcript!['transcript_document'], fileBytes);
      } else {
        fail('File not found in local storage: $fileName');
      }
    });
  });
}