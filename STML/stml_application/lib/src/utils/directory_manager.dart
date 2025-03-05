import 'dart:io';

import 'package:memoryminder/src/utils/constants.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

class DirectoryManager {
  static final DirectoryManager _instance = DirectoryManager._internal();

  late Directory _rootDirectory;
  late Directory _photosDirectory;
  late Directory _videosDirectory;
  late Directory _audiosDirectory;
  late Directory _transcriptsDirectory;
  late Directory _videoThumbnailsDirectory;
  late Directory _videoStillsDirectory;
  late Directory _videoResponsesDirectory;
  late Directory _significantObjectsDirectory;
  late Directory _tmpDirectory;

  DirectoryManager._internal();

  static DirectoryManager get instance => _instance;

  Directory get rootDirectory => _rootDirectory;
  Directory get photosDirectory => _photosDirectory;
  Directory get videosDirectory => _videosDirectory;
  Directory get audiosDirectory => _audiosDirectory;
  Directory get transcriptsDirectory => _transcriptsDirectory;
  Directory get videoStillsDirectory => _videoStillsDirectory;
  Directory get videoThumbnailsDirectory => _videoThumbnailsDirectory;
  Directory get videoResponsesDirectory => _videoResponsesDirectory;
  Directory get significantObjectsDirectory => _significantObjectsDirectory;
  Directory get tmpDirectory => _tmpDirectory;

  Future<void> initializeDirectories() async {
    try {
      _rootDirectory = await getApplicationDocumentsDirectory();
      _photosDirectory =
          _createDirectoryIfDoesNotExist('${_rootDirectory.path}$photosPath');
      _videosDirectory =
          _createDirectoryIfDoesNotExist('${_rootDirectory.path}$videosPath');
      _audiosDirectory =
          _createDirectoryIfDoesNotExist('${_rootDirectory.path}$audiosPath');
      _transcriptsDirectory = _createDirectoryIfDoesNotExist(
          '${_rootDirectory.path}$audioTranscriptsPath');
      _videoThumbnailsDirectory = _createDirectoryIfDoesNotExist(
          '${_rootDirectory.path}$videoThumbnailsPath');
      _videoStillsDirectory = _createDirectoryIfDoesNotExist(
          '${_rootDirectory.path}$videoStillsPath');
      _videoResponsesDirectory = _createDirectoryIfDoesNotExist(
          '${_rootDirectory.path}$videoResponsesPath');
      _significantObjectsDirectory = _createDirectoryIfDoesNotExist(
        '${_rootDirectory.path}$significantObjectsPath',
      );
      _tmpDirectory =
          _createDirectoryIfDoesNotExist('${_rootDirectory.path}$tmpPath');
    } catch (e) {
      appLogger.severe('Error initializing directories: $e');
    }
  }

  Directory _createDirectoryIfDoesNotExist(String directoryPath) {
    Directory directory = Directory(directoryPath);
    try {
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
    } catch (e) {
      appLogger.severe('Error creating directory: $e');
    }
    return directory;
  }
}
