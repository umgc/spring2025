import 'dart:io';


import 'package:memoryminder/src/address.dart';
import 'package:memoryminder/src/features/common/model/media_type.dart';
import 'package:memoryminder/src/features/common/model/video.dart';
import 'package:memoryminder/src/features/common/repository/video_repository.dart';
import 'package:memoryminder/src/utils/constants.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';

class VideoController {
  VideoController._();

  static Future<Video?> addSeedVideo({
    String? title,
    String? description,
    List<String>? tags,
    required File videoFile,
    File? thumbnailFile, // TODO: Update to auto get the thumbnail
    required String duration, // TODO: Update to auto get the duration
  }) async {
    try {
      DateTime timestamp = DateTime.now();
      String physicalAddress = defaultAddress;
      String videoFileExtension =
          FileManager().getFileExtensionFromFile(videoFile);
      String videoFileName = FileManager().generateFileName(
        MediaType.video.name,
        timestamp,
        videoFileExtension,
      );
      String? thumbnailFileExtension;
      String? thumbnailFileName;
      if (thumbnailFile != null) {
        thumbnailFileExtension =
            FileManager().getFileExtensionFromFile(thumbnailFile);
        thumbnailFileName =
            '${FileManager().getFileNameWithoutExtension(videoFileName)}.$thumbnailFileExtension';
      }
      int videoFileSize = FileManager.calculateFileSizeInBytes(videoFile);
      Video newVideo = Video(
        title: title,
        description: description,
        tags: tags,
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        storageSize: videoFileSize,
        isFavorited: false,
        videoFileName: videoFileName,
        thumbnailFileName: thumbnailFileName,
        duration: duration,
      );
      Video createdVideo = await VideoRepository.instance.create(newVideo);
      await FileManager.addFileToFilesystem(
        videoFile,
        DirectoryManager.instance.videosDirectory.path,
        videoFileName,
      );

      await FileManager.addFileToFilesystem(
        thumbnailFile!,
        DirectoryManager.instance.videoThumbnailsDirectory.path,
        thumbnailFileName!,
      );

      return createdVideo;
    } catch (e) {
      print('Video Controller -- Error adding video: $e');
      return null;
    }
  }

  static Future<Video?> addVideo({
    String? title,
    String? description,
    List<String>? tags,
    required File videoFile,
    File? thumbnailFile,
    String? duration,
  }) async {
    try {
      String videoFileName = FileManager.getFileName(videoFile.path);
      int videoFileSize = FileManager.calculateFileSizeInBytes(videoFile);
      DateTime timestamp =
          DateTime.parse(FileManager.getFileTimestamp(videoFile.path));
      String physicalAddress = "";
      await Address.whereIAm().then((String address) {
        physicalAddress = address;
      });
      String updatedPath = videoFile
          .path; // The method will update with the path (hopefully), when a video is added
      await FileManager.getThumbnail(updatedPath, 0, isThumbnail: true);
      String thumbnailFileName =
          FileManager.getThumbnailFileName(updatedPath, 0, isThumbnail: true);
      Video newVideo = Video(
        title: title ?? "",
        description: description ?? "",
        tags: tags ?? [],
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        storageSize: videoFileSize,
        isFavorited: false,
        videoFileName: videoFileName,
        thumbnailFileName: thumbnailFileName,
        duration: duration ?? "0",
      );

      Video createdVideo = await VideoRepository.instance.create(newVideo);
      return createdVideo;
    } catch (e) {
      print('Video Controller -- Error adding video: $e');
      return null;
    }
  }

  static Future<Video?> updateVideo({
    required int id,
    String? title,
    String? description,
    bool? isFavorited,
    List<String>? tags,
  }) async {
    try {
      final existingVideo = await VideoRepository.instance.read(id);
      final updatedVideo = existingVideo.copy(
        title: title ?? existingVideo.title,
        description: description ?? existingVideo.description,
        isFavorited: isFavorited ?? existingVideo.isFavorited,
        tags: tags ?? existingVideo.tags,
      );
      await VideoRepository.instance.update(updatedVideo);
      return updatedVideo;
    } catch (e) {
      print('Video Controller -- Error updating video: $e');
      return null;
    }
  }

  static Future<Video?> removeVideo(int id) async {
    try {
      final existingVideo = await VideoRepository.instance.read(id);
      await VideoRepository.instance.delete(id);
      final videoFilePath =
          '${DirectoryManager.instance.videosDirectory.path}/${existingVideo.videoFileName}';
      await FileManager.removeFileFromFilesystem(videoFilePath);
      String? thumbnailFileName = existingVideo.thumbnailFileName;
      if (thumbnailFileName != null && thumbnailFileName.isNotEmpty) {
        final thumbnailFilePath =
            '${DirectoryManager.instance.videoThumbnailsDirectory.path}/${existingVideo.thumbnailFileName}';
        await FileManager.removeFileFromFilesystem(thumbnailFilePath);
      }
      return existingVideo;
    } catch (e) {
      print('Video Controller -- Error removing video: $e');
      return null;
    }
  }
}
