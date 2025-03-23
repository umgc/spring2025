import 'dart:io';

import 'package:memoryminder/src/address.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';
import 'package:memoryminder/src/database/model/media_type.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/data/audio_repository.dart';
import 'package:memoryminder/src/utils/constants.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';

class AudioController {
  AudioController._();

  static Future<Audio?> addSeedAudio({
    String? title,
    String? description,
    List<String>? tags,
    required File audioFile,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      DateTime timestamp = DateTime.now();
      String physicalAddress = defaultAddress;
      String audioFileExtension =
          FileManager().getFileExtensionFromFile(audioFile);
      String audioFileName = FileManager().generateFileName(
        MediaType.audio.name,
        timestamp,
        audioFileExtension,
      );
      int audioFileSize = FileManager.calculateFileSizeInBytes(audioFile);
      String? transcriptFileName;
      if (transcriptFile != null) {
        String transcriptFileExtension =
            FileManager().getFileExtensionFromFile(transcriptFile);
        transcriptFileName = FileManager().generateFileName(
          transcriptType,
          timestamp,
          transcriptFileExtension,
        );
        await FileManager.addFileToFilesystem(
          transcriptFile,
          DirectoryManager.instance.transcriptsDirectory.path,
          transcriptFileName,
        );
      }

      Audio newAudio = Audio(
        title: title,
        description: description,
        tags: tags,
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        audioFileName: audioFileName,
        storageSize: audioFileSize,
        isFavorited: false,
        transcriptFileName: transcriptFileName,
        summary: summary,
      );

      Audio createdAudio = await AudioRepository.instance.create(newAudio);
      await FileManager.addFileToFilesystem(
        audioFile,
        DirectoryManager.instance.audiosDirectory.path,
        audioFileName,
      );
      return createdAudio;
    } catch (e) {
      appLogger.severe('Audio Controller -- Error adding audio: $e');
      return null;
    }
  }

  static Future<Audio?> addAudio({
    String? title,
    String? description,
    List<String>? tags,
    required File audioFile,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      DateTime timestamp = DateTime.now();
      String physicalAddress = "";
      await Address.whereIAm().then((String address) {
        physicalAddress = address;
      });
      String audioFileName = FileManager.getFileName(audioFile.path);
      int audioFileSize = FileManager.calculateFileSizeInBytes(audioFile);
      String? transcriptFileName;
      if (transcriptFile != null) {
        transcriptFileName = FileManager.getFileName(transcriptFile.path);
      }

      Audio newAudio = Audio(
        title: title,
        description: description,
        tags: tags,
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        audioFileName: audioFileName,
        storageSize: audioFileSize,
        isFavorited: false,
        transcriptFileName: transcriptFileName,
        summary: summary,
      );
      Audio createdAudio = await AudioRepository.instance.create(newAudio);
      return createdAudio;
    } catch (e) {
      appLogger.severe('Audio Controller -- Error adding audio: $e');
      return null;
    }
  }

  static Future<Audio?> updateAudio({
    required int id,
    String? title,
    String? description,
    bool? isFavorited,
    List<String>? tags,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      final existingAudio = await AudioRepository.instance.read(id);
      String? updatedTranscriptFileName;
      if (transcriptFile != null) {
        updatedTranscriptFileName =
            FileManager.getFileName(transcriptFile.path);
      }

      final updatedAudio = existingAudio.copy(
        title: title ?? existingAudio.title,
        description: description ?? existingAudio.description,
        isFavorited: isFavorited ?? existingAudio.isFavorited,
        tags: tags ?? existingAudio.tags,
        transcriptFileName: updatedTranscriptFileName,
        summary: summary ?? existingAudio.summary,
      );

      await AudioRepository.instance.update(updatedAudio);
      return updatedAudio;
    } catch (e) {
      appLogger.severe('Audio Controller -- Error updating audio: $e');
      return null;
    }
  }

  static Future<Audio?> removeAudio(int id) async {
    try {
      final existingAudio = await AudioRepository.instance.read(id);
      await AudioRepository.instance.delete(id);
      final audioFilePath =
          '${DirectoryManager.instance.audiosDirectory.path}/${existingAudio.audioFileName}';
      await FileManager.removeFileFromFilesystem(audioFilePath);
      if (existingAudio.transcriptFileName != null) {
        final transcriptFilePath =
            '${DirectoryManager.instance.transcriptsDirectory.path}/${existingAudio.transcriptFileName}';
        await FileManager.removeFileFromFilesystem(transcriptFilePath);
      }
      return existingAudio;
    } catch (e) {
      appLogger.severe('Audio Controller -- Error removing audio: $e');
      return null;
    }
  }
}
