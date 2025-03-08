import 'dart:io';

import 'package:memoryminder/src/database/model/significant_object.dart';
import 'package:memoryminder/src/database/repository/significant_object_repository.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';

const String significantObjectType = 'significant_object';

class SignificantObjectController {
  SignificantObjectController._();

  static Future<SignificantObject?> addSignificantObject({
    String? objectLabel,
    String? customLabel,
    required int timestamp,
    required double left,
    required double top,
    required double width,
    required double height,
    required File imageFile,
  }) async {
    try {
      String imageFileExtension =
          FileManager().getFileExtensionFromFile(imageFile);
      String imageFileName = FileManager().generateFileName(
        significantObjectType,
        DateTime.now(),
        imageFileExtension,
      );
      SignificantObject newObject = SignificantObject(
        objectLabel: objectLabel,
        customLabel: customLabel,
        timestamp: timestamp,
        imageFileName: imageFileName,
        left: left,
        top: top,
        width: width,
        height: height,
      );
      SignificantObject createdObject =
          await SignificantObjectRepository.instance.create(newObject);
      await FileManager.addFileToFilesystem(
        imageFile,
        DirectoryManager.instance.significantObjectsDirectory.path,
        imageFileName,
      );
      return createdObject;
    } catch (e) {
      appLogger
          .severe('SignificantObject Controller -- Error adding object: $e');
      return null;
    }
  }

  static Future<SignificantObject?> updateSignificantObjectLabels({
    required int id,
    String? objectLabel,
    String? customLabel,
  }) async {
    try {
      final existingObject =
          await SignificantObjectRepository.instance.read(id);
      final updatedObject = existingObject.copy(
        objectLabel: objectLabel ?? existingObject.objectLabel,
        customLabel: customLabel ?? existingObject.customLabel,
      );
      await SignificantObjectRepository.instance.update(updatedObject);
      return updatedObject;
    } catch (e) {
      appLogger.severe(
          'SignificantObject Controller -- Error updating object labels: $e');
      return null;
    }
  }

  static Future<SignificantObject?> removeSignificantObject(int id) async {
    try {
      final existingObject =
          await SignificantObjectRepository.instance.read(id);
      await SignificantObjectRepository.instance.delete(id);
      final imageFilePath =
          '${DirectoryManager.instance.significantObjectsDirectory.path}/${existingObject.imageFileName}';
      await FileManager.removeFileFromFilesystem(imageFilePath);
      return existingObject;
    } catch (e) {
      appLogger
          .severe('SignificantObject Controller -- Error removing object: $e');
      return null;
    }
  }
}
