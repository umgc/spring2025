import 'package:memoryminder/src/address.dart';
import 'package:memoryminder/src/database/model/video_response.dart';
import 'package:memoryminder/src/database/repository/video_response_repository.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:path/path.dart' as path;

const String videoResponseType = 'video_response';

class VideoResponseController {
  VideoResponseController._();

  static Future<VideoResponse?> addVideoResponse({
    required String title,
    required String referenceVideoFilePath,
    required double confidence,
    required int timestamp,
    required double left,
    required double top,
    required double width,
    required double height,
    String? address,
    String? parents,
  }) async {
    try {
      String referenceVideo =
          FileManager.getFileName(path.basename(referenceVideoFilePath));
      String physicalAddress = '';
      await Address.whereIAm().then((String address) {
        physicalAddress = address;
      });
      VideoResponse newResponse = VideoResponse(
        title: title,
        referenceVideoFilePath: referenceVideo,
        timestamp: timestamp,
        confidence: confidence,
        left: left,
        top: top,
        width: width,
        height: height,
        address: physicalAddress,
        parents: parents,
      );
      VideoResponse createdResponse =
          await VideoResponseRepository.instance.create(newResponse);

      return createdResponse;
    } catch (e) {
      appLogger
          .severe('Video Response Controller -- Error adding response: $e');
      return null;
    }
  }

  static Future<VideoResponse?> updateVideoResponse({
    required int id,
    String? title,
    double? confidence,
    double? left,
    double? top,
    double? width,
    double? height,
    String? address,
    String? parents,
  }) async {
    try {
      final existingResponse = await VideoResponseRepository.instance.read(id);
      final updatedResponse = existingResponse.copy(
        title: title ?? existingResponse.title,
        confidence: confidence ?? existingResponse.confidence,
        left: left ?? existingResponse.left,
        top: top ?? existingResponse.top,
        width: width ?? existingResponse.width,
        height: height ?? existingResponse.height,
        address: address ?? existingResponse.address,
        parents: parents ?? existingResponse.parents,
      );
      await VideoResponseRepository.instance.update(updatedResponse);
      return updatedResponse;
    } catch (e) {
      appLogger
          .severe('Video Response Controller -- Error updating response: $e');
      return null;
    }
  }

  static Future<VideoResponse?> removeVideoResponse(int id) async {
    try {
      final existingResponse = await VideoResponseRepository.instance.read(id);
      await VideoResponseRepository.instance.delete(id);
      final imageFilePath =
          '${DirectoryManager.instance.videoStillsDirectory.path}/${existingResponse.referenceVideoFilePath}';
      await FileManager.removeFileFromFilesystem(imageFilePath);
      return existingResponse;
    } catch (e) {
      appLogger
          .severe('Video Response Controller -- Error removing response: $e');
      return null;
    }
  }
}
