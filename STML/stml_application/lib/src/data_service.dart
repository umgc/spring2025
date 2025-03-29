import 'dart:io';

import 'package:memoryminder/src/features/common/controller/photo_controller.dart';
import 'package:memoryminder/src/features/common/controller/video_controller.dart';
import 'package:memoryminder/src/features/common/model/media.dart';
import 'package:memoryminder/src/features/common/model/photo.dart';
import 'package:memoryminder/src/features/common/model/video.dart';
import 'package:memoryminder/src/features/common/model/video_response.dart';
import 'package:memoryminder/src/features/common/repository/photo_repository.dart';
import 'package:memoryminder/src/features/common/repository/video_repository.dart';
import 'package:memoryminder/src/features/common/repository/video_response_repository.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/application/audio_controller.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/domain/audio.dart';
import 'package:memoryminder/src/utils/format_utils.dart';
import 'package:memoryminder/src/features/sensitive_information_detection/data/audio_repository.dart';
import 'package:memoryminder/src/utils/logger.dart';

class DataService {
  DataService._internal();

  static final DataService _instance = DataService._internal();
  static DataService get instance => _instance;

  late List<Media> mediaList = [];
  late List<VideoResponse> responseList = [];
  bool hasBeenInitialized = false;

  Future<void> initializeData() async {
    await loadMedia();
  }

  // Used to show local database and objects
// Used to show local database and objects
  Future<void> loadMedia() async {
    final audios = await AudioRepository.instance.readAll();
    final photos = await PhotoRepository.instance.readAll();
    final videos = await VideoRepository.instance.readAll();

    mediaList = [...audios, ...photos, ...videos];

    if (!hasBeenInitialized) {
      FormatUtils.logBigMessage("LOCAL DATABASE OBJECTS START");

      if (audios.isNotEmpty) {
        FormatUtils.logBigMessage("AUDIO OBJECTS START");
        for (var audio in audios) {
          print('Audio #${audio.id}: ${audio.toJson()}');
        }
        FormatUtils.logBigMessage("AUDIO OBJECTS END");
      }

      if (photos.isNotEmpty) {
        FormatUtils.logBigMessage("PHOTO OBJECTS START");
        for (var photo in photos) {
          print('Photo #${photo.id}: ${photo.toJson()}');
        }
        FormatUtils.logBigMessage("PHOTO OBJECTS END");
      }

      if (videos.isNotEmpty) {
        FormatUtils.logBigMessage("VIDEO OBJECTS START");
        for (var video in videos) {
          print('Video #${video.id}: ${video.toJson()}');
        }
        FormatUtils.logBigMessage("VIDEO OBJECTS END");
      }

      responseList = await VideoResponseRepository.instance.readAll();

      if (responseList.isNotEmpty) {
        FormatUtils.logBigMessage("VIDEO RESPONSES START");
        for (var videoResponse in responseList) {
          print("Response # ${videoResponse.toJson()}");
        }
        FormatUtils.logBigMessage("VIDEO RESPONSES END");
      }



      FormatUtils.logBigMessage("LOCAL DATABASE OBJECTS END");
      hasBeenInitialized = true;
    }
  }

  Future<void> unloadMedia() async {
    mediaList.clear();
  }

  Future<void> refreshMedia() async {
    await unloadMedia();
    await loadMedia();
  }

  Future<void> loadResponses() async {
    responseList = await VideoResponseRepository.instance.readAll();
  }

  Future<void> unloadResponses() async {
    responseList.clear();
  }

  Future<void> refreshResponses() async {
    await unloadResponses();
    await loadResponses();
  }

  // |-------------------------------------------------------------------------|
  // |---------------------- VIDEO RESPONSE OPERATIONS ------------------------|
  // |-------------------------------------------------------------------------|



  // |-------------------------------------------------------------------------|
  // |--------------------------- AUDIO OPERATIONS ----------------------------|
  // |-------------------------------------------------------------------------|

  // TODO, refactor seed data to just use addAudio();
  Future<Audio?> addSeedAudio({
    String? title,
    String? description,
    List<String>? tags,
    required File audioFile,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      final audio = await AudioController.addSeedAudio(
        title: title,
        description: description,
        tags: tags,
        audioFile: audioFile,
        transcriptFile: transcriptFile,
        summary: summary,
      );
      if (audio != null) {
        await refreshMedia();
      }
      return audio;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding audio: $e');
      return null;
    }
  }

  Future<Audio?> addAudio({
    String? title,
    String? description,
    List<String>? tags,
    required File audioFile,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      final audio = await AudioController.addAudio(
        title: title,
        description: description,
        tags: tags,
        audioFile: audioFile,
        transcriptFile: transcriptFile,
        summary: summary,
      );
      if (audio != null) {
        await refreshMedia();
      }
      return audio;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding audio: $e');
      return null;
    }
  }

  Future<Audio?> updateAudio({
    required int id,
    String? title,
    String? description,
    List<String>? tags,
    bool? isFavorited,
    File? transcriptFile,
    String? summary,
  }) async {
    try {
      final audio = await AudioController.updateAudio(
        id: id,
        title: title,
        description: description,
        isFavorited: isFavorited,
        tags: tags,
        transcriptFile: transcriptFile,
        summary: summary,
      );
      if (audio != null) {
        await refreshMedia();
      }
      return audio;
    } catch (e) {
      appLogger.severe('Data Service -- Error updating audio: $e');
      return null;
    }
  }

  Future<Audio?> removeAudio(int id) async {
    try {
      final audio = await AudioController.removeAudio(id);
      if (audio != null) {
        await refreshMedia();
      }
      return audio;
    } catch (e) {
      appLogger.severe('Data Service -- Error removing audio: $e');
      return null;
    }
  }

  // |-------------------------------------------------------------------------|
  // |--------------------------- PHOTO OPERATIONS ----------------------------|
  // |-------------------------------------------------------------------------|

// TODO, refactor seed data to just use addPhoto();
  Future<Photo?> addSeedPhoto({
    String? title,
    String? description,
    List<String>? tags,
    required File photoFile,
  }) async {
    try {
      final photo = await PhotoController.addSeedPhoto(
        title: title,
        description: description,
        tags: tags,
        photoFile: photoFile,
      );
      if (photo != null) {
        await refreshMedia();
      }
      return photo;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding photo: $e');
      return null;
    }
  }

  Future<Photo?> addPhoto({
    String? title,
    String? description,
    List<String>? tags,
    required File photoFile,
  }) async {
    try {
      final photo = await PhotoController.addPhoto(
        title: title,
        description: description,
        tags: tags,
        photoFile: photoFile,
      );
      if (photo != null) {
        await refreshMedia();
      }
      return photo;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding photo: $e');
      return null;
    }
  }

  Future<Photo?> updatePhoto({
    required int id,
    String? title,
    String? description,
    bool? isFavorited,
    List<String>? tags,
  }) async {
    try {
      final photo = await PhotoController.updatePhoto(
        id: id,
        title: title,
        description: description,
        isFavorited: isFavorited,
        tags: tags,
      );
      if (photo != null) {
        await refreshMedia();
      }
      return photo;
    } catch (e) {
      appLogger.severe('Data Service -- Error updating photo: $e');
      return null;
    }
  }

  Future<Photo?> removePhoto(int id) async {
    try {
      final photo = await PhotoController.removePhoto(id);
      if (photo != null) {
        await refreshMedia();
      }
      return photo;
    } catch (e) {
      appLogger.severe('Data Service -- Error removing photo: $e');
      return null;
    }
  }

  // |-------------------------------------------------------------------------|
  // |--------------------------- VIDEO OPERATIONS ----------------------------|
  // |-------------------------------------------------------------------------|

  // TODO, refactor seed data to just use addVideo();
  Future<Video?> addSeedVideo({
    String? title,
    String? description,
    List<String>? tags,
    required File videoFile,
    File? thumbnailFile,
    required String duration,
  }) async {
    try {
      final video = await VideoController.addSeedVideo(
        title: title,
        description: description,
        tags: tags,
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        duration: duration,
      );
      if (video != null) {
        await refreshMedia();
      }
      return video;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding video: $e');
      return null;
    }
  }

  Future<Video?> addVideo({
    String? title,
    String? description,
    List<String>? tags,
    required File videoFile,
    File? thumbnailFile,
    String? duration,
  }) async {
    try {
      final video = await VideoController.addVideo(
        title: title,
        description: description,
        tags: tags,
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        duration: duration,
      );
      if (video != null) {
        await refreshMedia();
      }
      return video;
    } catch (e) {
      appLogger.severe('Data Service -- Error adding video: $e');
      return null;
    }
  }

  Future<Video?> updateVideo({
    required int id,
    String? title,
    String? description,
    bool? isFavorited,
    List<String>? tags,
  }) async {
    try {
      final video = await VideoController.updateVideo(
        id: id,
        title: title,
        description: description,
        isFavorited: isFavorited,
        tags: tags,
      );
      if (video != null) {
        await refreshMedia();
      }
      return video;
    } catch (e) {
      appLogger.severe('Data Service -- Error updating video: $e');
      return null;
    }
  }

  Future<Video?> removeVideo(int id) async {
    try {
      final video = await VideoController.removeVideo(id);
      if (video != null) {
        await refreshMedia();
      }
      return video;
    } catch (e) {
      appLogger.severe('Data Service -- Error removing video: $e');
      return null;
    }
  }





  // |-------------------------------------------------------------------------|
  // |--------------------------- OTHER OPERATIONS ----------------------------|
  // |-------------------------------------------------------------------------|

  Future<Media?> updateMediaIsFavorited(Media media, bool isFavorited) async {
    try {
      Media? updatedMedia;
      if (media is Audio) {
        updatedMedia = await updateAudio(
          id: media.id!,
          isFavorited: isFavorited,
        );
      } else if (media is Photo) {
        updatedMedia = await updatePhoto(
          id: media.id!,
          isFavorited: isFavorited,
        );
      } else if (media is Video) {
        updatedMedia = await updateVideo(
          id: media.id!,
          isFavorited: isFavorited,
        );
      }
      return updatedMedia;
    } catch (e) {
      appLogger.severe('Data Service -- Error updating media isFavorited: $e');
      return null;
    }
  }

  Future<Media?> updateMediaTags(Media media, List<String>? tags) async {
    try {
      Media? updatedMedia;
      if (media is Audio) {
        updatedMedia = await updateAudio(
          id: media.id!,
          tags: tags,
        );
      } else if (media is Photo) {
        updatedMedia = await updatePhoto(
          id: media.id!,
          tags: tags,
        );
      } else if (media is Video) {
        updatedMedia = await updateVideo(
          id: media.id!,
          tags: tags,
        );
      }
      return updatedMedia;
    } catch (e) {
      appLogger.severe('Data Service -- Error updating media tags: $e');
      return null;
    }
  }
}
