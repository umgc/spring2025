import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'database_helper.mocks.dart';

void main() {
  late MockDatabaseHelper mockDataHelper;

  setUp(() {
    mockDataHelper = MockDatabaseHelper();
  });

  group('DatabaseHelper Tests', () {
    test('should get transcript text data and industry by ID', () async {
      int transcriptId = 1;
      Map<String, String> mockTranscriptData = {
        'transcript_text_data': 'Sample text',
        'industry': 'Sample industry',
      };

      when(mockDataHelper.getTranscriptTextDataAndIndustryById(transcriptId))
          .thenAnswer((_) async => mockTranscriptData);

      final transcriptData = await mockDataHelper.getTranscriptTextDataAndIndustryById(transcriptId);
      expect(transcriptData, isNotNull);
      expect(transcriptData!['transcript_text_data'], 'Sample text');
      expect(transcriptData['industry'], 'Sample industry');
    });

    test('should update transcript document', () async {
      int transcriptId = 1;
      List<int> documentBytes = [1, 2, 3, 4, 5];

      when(mockDataHelper.updateTranscriptDocument(transcriptId, documentBytes))
          .thenAnswer((_) async => true);

      final result = await mockDataHelper.updateTranscriptDocument(transcriptId, documentBytes);
      expect(result, true);
    });

    test('should get transcript by ID', () async {
      int transcriptId = 1;
      Map<String, dynamic> mockTranscript = {
        'transcript_id': transcriptId,
        'transcript_text_data': 'Sample text',
        'industry': 'Sample industry',
      };

      when(mockDataHelper.getTranscriptById(transcriptId))
          .thenAnswer((_) async => mockTranscript);

      final transcript = await mockDataHelper.getTranscriptById(transcriptId);
      expect(transcript, isNotNull);
      expect(transcript!['transcript_id'], transcriptId);
    });

    test('should insert AI response', () async {
      int transcriptId = 1;
      String aiResponse = 'This is an AI response';

      when(mockDataHelper.insertAiResponse(transcriptId, aiResponse))
          .thenAnswer((_) async => 1);

      final result = await mockDataHelper.insertAiResponse(transcriptId, aiResponse);
      expect(result, 1);
    });
  });
}