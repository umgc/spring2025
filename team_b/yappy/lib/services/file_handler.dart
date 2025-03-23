import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:yappy/services/database_helper.dart';
import 'package:flutter/foundation.dart';

class FileHandler {
  Future<String> get localStoragePath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get databasePath async {
    final databasesPath = await getDatabasesPath();
    return join(databasesPath, 'yappy_database.db');
  }

  Future<void> addDocument(File file) async {
    try {
      final path = await localStoragePath;
      final newFile = File(join(path, basename(file.path)));
      await file.copy(newFile.path);
      if (kDebugMode) {
        print('File added to local storage: ${newFile.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding document: $e');
      }
    }
  }

  // Used to move a file the user uploads from local storage to the database
  Future<void> moveFileToDatabase(DatabaseHelper dbHelper, String fileName, int transcriptId) async {
    try {
      final path = await localStoragePath;
      final file = File(join(path, fileName));
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        await dbHelper.insertDocument(transcriptId, fileName, bytes);

        await file.delete();
        if (kDebugMode) {
          print('File moved to database and deleted from local storage: $fileName');
        }
      } else {
        if (kDebugMode) {
          print('File not found in local storage: $fileName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error moving file to database: $e');
      }
    }
  }

  // Method to save transcript text data to local storage as a text file
  Future<String> saveTranscriptTextToLocal(DatabaseHelper dbHelper, int transcriptId) async {
    try {
      final transcriptData = await dbHelper.getTranscriptTextDataAndIndustryById(transcriptId);
      if (transcriptData != null) {
        final textData = transcriptData['transcript_text_data']!;
        final industry = transcriptData['industry']!;
        final fileName = 'transcript_text_${transcriptId}_$industry.txt';
        final path = await localStoragePath;
        final file = File(join(path, fileName));
        await file.writeAsString(textData);
        if (kDebugMode) {
          print('Transcript text data saved to local storage: $fileName');
        }
        return fileName;
      } else {
        if (kDebugMode) {
          print('No transcript data found for ID: $transcriptId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving transcript text data to local storage: $e');
      }
    }
    return '';
  }

  // Method to save document (BLOB) to local storage as a text file
  Future<void> saveDocumentToLocal(DatabaseHelper dbHelper, int transcriptId) async {
    try {
      final documentData = await dbHelper.getDocumentAndIndustryById(transcriptId);
      if (documentData != null) {
        final documentBytes = documentData['transcript_document'] as List<int>?;
        final industry = documentData['industry']!;
        if (documentBytes != null) {
          final fileName = 'transcript_document_${transcriptId}_$industry.txt';
          final path = await localStoragePath;
          final file = File(join(path, fileName));
          await file.writeAsBytes(documentBytes);
          if (kDebugMode) {
            print('Document saved to local storage: $fileName');
          }
        } else {
          if (kDebugMode) {
            print('No document found for ID: $transcriptId');
          }
        }
      } else {
        if (kDebugMode) {
          print('No document data found for ID: $transcriptId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving document to local storage: $e');
      }
    }
  }

  Future<void> deleteFile(String fileName) async {
    try {
      final path = await localStoragePath;
      final file = File(join(path, fileName));
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('File deleted from local storage: $fileName');
        }
      } else {
        if (kDebugMode) {
          print('File not found in local storage: $fileName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting file: $e');
      }
    }
  }

  Future<void> copyAssetToLocalStorage(String assetPath, String fileName) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final file = File(join(await localStoragePath, fileName));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      if (kDebugMode) {
        print('File copied from assets to local storage: $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error copying file from assets to local storage: $e');
      }
    }
  }
}