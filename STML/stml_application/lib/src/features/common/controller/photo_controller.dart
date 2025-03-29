import 'dart:io';

import 'package:memoryminder/src/address.dart';
import 'package:memoryminder/src/features/common/model/media_type.dart';
import 'package:memoryminder/src/features/common/model/photo.dart';
import 'package:memoryminder/src/features/common/repository/photo_repository.dart';
import 'package:memoryminder/src/utils/constants.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';

class PhotoController {
  PhotoController._();

  static Future<Photo?> addSeedPhoto({
    String? title,
    String? description,
    List<String>? tags,
    required File photoFile,
  }) async {
    try {
      DateTime timestamp = DateTime.now();
      String physicalAddress = defaultAddress;
      String photoFileExtension =
          FileManager().getFileExtensionFromFile(photoFile);
      String photoFileName = FileManager().generateFileName(
        MediaType.photo.name,
        timestamp,
        photoFileExtension,
      );
      int photoFileSize = FileManager.calculateFileSizeInBytes(photoFile);
      Photo newPhoto = Photo(
        title: title,
        description: description,
        tags: tags,
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        photoFileName: photoFileName,
        storageSize: photoFileSize,
        isFavorited: false,
      );
      Photo createdPhoto = await PhotoRepository.instance.create(newPhoto);
      await FileManager.addFileToFilesystem(
        photoFile,
        DirectoryManager.instance.photosDirectory.path,
        photoFileName,
      );
      return createdPhoto;
    } catch (e) {
      print('Photo Controller -- Error adding photo: $e');
      return null;
    }
  }

  static Future<Photo?> addPhoto({
    String? title,
    String? description,
    List<String>? tags,
    required File photoFile,
  }) async {
    try {
      String photoFileName = FileManager.getFileName(photoFile.path);
      int photoFileSize = FileManager.calculateFileSizeInBytes(photoFile);
      DateTime timestamp =
          DateTime.parse(FileManager.getFileTimestamp(photoFile.path));
      String physicalAddress = '';
      await Address.whereIAm().then((String address) {
        physicalAddress = address;
      });
      Photo newPhoto = Photo(
        title: title ?? "",
        description: description ?? "",
        tags: tags ?? [],
        timestamp: timestamp,
        physicalAddress: physicalAddress,
        photoFileName: photoFileName,
        storageSize: photoFileSize,
        isFavorited: false,
      );
      Photo createdPhoto = await PhotoRepository.instance.create(newPhoto);
      return createdPhoto;
    } catch (e) {
      print('Photo Controller -- Error adding photo: $e');
      return null;
    }
  }

  static Future<Photo?> updatePhoto({
    required int id,
    String? title,
    String? description,
    bool? isFavorited,
    List<String>? tags,
  }) async {
    try {
      final existingPhoto = await PhotoRepository.instance.read(id);
      final updatedPhoto = existingPhoto.copy(
        title: title ?? existingPhoto.title,
        description: description ?? existingPhoto.description,
        isFavorited: isFavorited ?? existingPhoto.isFavorited,
        tags: tags ?? existingPhoto.tags,
      );
      await PhotoRepository.instance.update(updatedPhoto);
      return updatedPhoto;
    } catch (e) {
      print('Photo Controller -- Error updating photo: $e');
      return null;
    }
  }

  static Future<Photo?> removePhoto(int id) async {
    try {
      final existingPhoto = await PhotoRepository.instance.read(id);
      await PhotoRepository.instance.delete(id);
      final photoFilePath =
          '${DirectoryManager.instance.photosDirectory.path}/${existingPhoto.photoFileName}';
      await FileManager.removeFileFromFilesystem(photoFilePath);
      return existingPhoto;
    } catch (e) {
      print('Photo Controller -- Error removing photo: $e');
      return null;
    }
  }
}
