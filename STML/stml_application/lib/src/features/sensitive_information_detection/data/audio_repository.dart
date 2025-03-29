import 'dart:io';
import 'package:memoryminder/src/features/common/database/app_database.dart';
import 'package:memoryminder/src/features/common/model/media.dart';
import 'package:memoryminder/src/features/common/service/s3_connection.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';


import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

const String tableAudios = 'audios';
const String transcriptType = 'transcript';

class AudioFields extends MediaFields {
  static final List<String> values = [
    ...MediaFields.values,
    audioFileName,
    transcriptFileName,
    summary,
    s3Url, // NEW: Storing S3 URL
  ];

  static const String audioFileName = 'audio_file_name';
  static const String transcriptFileName = 'transcript_file_name';
  static const String summary = 'summary';
  static const String s3Url = 's3_url'; // NEW: Column for S3 URL
}

// Repository class to handle CRUD operations for audio recordings
class AudioRepository {
  static final AudioRepository instance = AudioRepository._init();

  AudioRepository._init();

  /// Inserts a new audio entry into the database and returns the created entry.
  Future<Audio> create(Audio audio) async {
    final db = await AppDatabase.instance.database;
    final id = await db.insert(tableAudios, audio.toJson());
    return audio.copy(id: id);
  }

  /// Fetches an audio entry by its ID.
  Future<Audio> read(int id) async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query(
      tableAudios,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Audio.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  /// Fetches all audio entries from the database.
  Future<List<Audio>> readAll() async {
    final db = await AppDatabase.instance.database;
    const orderBy = '${MediaFields.timestamp} DESC';
    final result = await db.query(tableAudios, orderBy: orderBy);
    return result.map((json) => Audio.fromJson(json)).toList();
  }

  /// Updates an existing audio entry in the database.
  Future<int> update(Audio audio) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      tableAudios,
      audio.toJson(),
      where: '${MediaFields.id} = ?',
      whereArgs: [audio.id],
    );
  }

  /// Deletes an audio entry by its ID and also removes it from AWS S3.
  Future<int> delete(int id) async {
    final db = await AppDatabase.instance.database;
    final audio = await read(id);

    if (audio.s3Url != null) {
      final s3Service = S3Service();
      await s3Service.deleteFileFromS3(audio.s3Url!);
    }

    return await db.delete(
      tableAudios,
      where: '${MediaFields.id} = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all audio entries.
  Future<int> deleteAll() async {
    final db = await AppDatabase.instance.database;
    return await db.delete(tableAudios);
  }

  /// Counts the total number of audio recordings stored.
  Future<int> count() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $tableAudios');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Saves the audio metadata and S3 URL to the database.
  Future<Audio?> sendToDatabase({
    required String title,
    String? description,
    List<String>? tags,
    required String localAudioPath,
    required String s3Url, // NEW: S3 URL must be stored
    String? transcriptFilePath,
    String? summary,
  }) async {
    try {
      final timestamp = DateTime.now();
      final storageSize = await File(localAudioPath).length();
      final audioFileName = FileManager.getFileName(localAudioPath);
      final transcriptFileName = transcriptFilePath != null
          ? FileManager.getFileName(transcriptFilePath)
          : null;

      final audio = Audio(
        title: title,
        description: description,
        tags: tags,
        timestamp: timestamp,
        physicalAddress: "", // Can be updated with location services
        storageSize: storageSize,
        isFavorited: false,
        audioFileName: audioFileName,
        transcriptFileName: transcriptFileName,
        summary: summary,
        s3Url: s3Url, // NEW: Store S3 URL
      );

      return await create(audio);
    } catch (e) {
      appLogger.severe("Error saving audio to database: $e");
      return null;
    }
  }
}
