import 'dart:io';

import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';

class AppSeedData {
  void loadAppSeedData() async {
    await loadSeedAudio();
    await loadSeedPhoto();
    await loadSeedVideo();
  }

  Future<void> loadSeedAudio() async {
    try {
      File? audioFile = await FileManager.loadAssetFile(
          'assets/seed_data_files/bird.mp3', 'bird.mp3');
      File? transcriptFile = await FileManager.loadAssetFile(
          'assets/seed_data_files/bird_transcript.txt', 'bird_transcript.txt');
      List<String>? tagsList = ['nature', 'bird'];
      await DataService.instance.addSeedAudio(
          title: 'Bird',
          description: 'Audio of birds singing in the forest.',
          tags: tagsList,
          audioFile: audioFile,
          transcriptFile: transcriptFile,
          summary: 'This is a nature recording of birds singing.');
      FileManager.unloadAssetFile('bird.mp3');
    } catch (e) {
      appLogger.severe('Error loading seed data photo: $e');
    }
  }

  Future<void> loadSeedPhoto() async {
    try {
      File? photoFile = await FileManager.loadAssetFile(
          'assets/seed_data_files/cat.png', 'cat.png');
      List<String>? tagsList = ['pet', 'cat'];
      await DataService.instance.addSeedPhoto(
        title: 'Cat',
        description: 'A photo of my pet cat, Kit Kat.',
        tags: tagsList,
        photoFile: photoFile,
      );
      FileManager.unloadAssetFile('cat.png');
    } catch (e) {
      appLogger.severe('Error loading seed data photo: $e');
    }
  }

  Future<void> loadSeedVideo() async {
    try {
      File? videoFile = await FileManager.loadAssetFile(
          'assets/seed_data_files/dog.mp4', 'dog.mp4');
      File? thumbnailFile = await FileManager.loadAssetFile(
          'assets/seed_data_files/dog.png', 'dog.png');
      List<String>? tagsList = ['pet', 'dog'];
      await DataService.instance.addSeedVideo(
        title: 'Dog',
        description: 'A video of my pet dog, Spot.',
        tags: tagsList,
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        duration: '00:08',
      );
      FileManager.unloadAssetFile('dog.mp4');
      FileManager.unloadAssetFile('dog.png');
    } catch (e) {
      appLogger.severe('Error loading seed data video: $e');
    }
  }
}
