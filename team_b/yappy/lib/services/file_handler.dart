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