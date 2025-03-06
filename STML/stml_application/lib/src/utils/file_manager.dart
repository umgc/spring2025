import 'dart:io';
import 'dart:math';

import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:video_thumbnail/video_thumbnail.dart';

class FileManager {
  static String mostRecentVideoPath = "";
  static String mostRecentVideoName = "";

  static Future<void> addFileToFilesystem(File sourceFile,
      String targetDirectoryPath, String targetFilename) async {
    try {
      final targetPath = '$targetDirectoryPath/$targetFilename';
      await sourceFile.copy(targetPath);
    } catch (e) {
      appLogger.severe('Error adding file: $e');
    }
  }

  static Future<void> removeFileFromFilesystem(String filePath) async {
    try {
      final File fileToDelete = File(filePath);

      if (fileToDelete.existsSync()) {
        await fileToDelete.delete();
      }
    } catch (e) {
      appLogger.severe('Error deleting file: $e');
    }
  }

  static Future<void> updateFileInFileSystem(File sourceFile,
      String targetDirectoryPath, String targetFilename) async {
    try {
      final targetPath = '$targetDirectoryPath/$targetFilename';
      await removeFileFromFilesystem(targetPath);
      await addFileToFilesystem(
          sourceFile, targetDirectoryPath, targetFilename);
    } catch (e) {
      appLogger.severe('Error updating file: $e');
    }
  }

  static Future<File> loadAssetFile(
      String assetPath, String targetFileName) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final tmpDirectory = DirectoryManager.instance.tmpDirectory;
      final file = File('${tmpDirectory.path}/$targetFileName');
      File savedFile = await file.writeAsBytes(data.buffer.asUint8List());
      return savedFile;
    } catch (e) {
      appLogger.severe('Error loading asset: $e');
      throw Exception('Failed to load asset file: $assetPath');
    }
  }

  static Future<void> unloadAssetFile(String targetFileName) async {
    try {
      final tmpDirectory = DirectoryManager.instance.tmpDirectory;
      final file = File('${tmpDirectory.path}/$targetFileName');

      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      appLogger.severe('Error unloading asset file: $e');
    }
  }

  static int calculateFileSizeInBytes(File file) {
    try {
      if (file.existsSync()) {
        return file.lengthSync();
      } else {
        return 0;
      }
    } catch (e) {
      appLogger.severe('Error calculating file size: $e');
      return 0;
    }
  }

  String generateFileName(
      String prefix, DateTime timestamp, String fileExtension) {
    final random = Random();
    final formattedTimestamp = timestamp.millisecondsSinceEpoch;
    final randomString = String.fromCharCodes(
      List.generate(8, (_) => random.nextInt(26) + 97),
    );

    return '$prefix-$formattedTimestamp-$randomString.$fileExtension';
  }

  String getFileExtensionFromFile(File file) {
    return path.extension(file.path).replaceAll('.', '');
  }

  String getFileNameWithoutExtension(String fileNameWithExtension) {
    int lastIndex = fileNameWithExtension.lastIndexOf('.');
    if (lastIndex != -1) {
      return fileNameWithExtension.substring(0, lastIndex);
    }
    return fileNameWithExtension;
  }

  static Image? loadImage(String filePath, String fileName) {
    try {
      final File imageFile = File('$filePath/$fileName');
      if (!imageFile.existsSync()) {
        return null;
      }
      return Image.file(imageFile);
    } catch (e) {
      appLogger.severe('Error loading image: $e');
      return null;
    }
  }

  static File? loadFile(String filePath, String fileName) {
    try {
      final File file = File('$filePath/$fileName');
      if (!file.existsSync()) {
        return null;
      }
      return file;
    } catch (e) {
      appLogger.severe('Error loading file: $e');
      return null;
    }
  }

  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  static String getFileTimestamp(String filePath) {
    // Get the file name from the full file path
    String fileName = getFileName(filePath);

    // Find the last dot (.) in the file name to separate the extension
    int dotIndex = fileName.lastIndexOf('.');

    String newName = fileName.replaceFirst("_", " ");

    if (dotIndex != -1) {
      // Return the file name without the extension
      return newName.substring(0, dotIndex);
    } else {
      // If there's no dot in the file name, return the entire name
      return newName;
    }
  }

  static String getThumbnailFileName(String vidPath, int timesStamp,
      {bool isThumbnail = false}) {
    String outputPath = isThumbnail
        ? DirectoryManager.instance.videoThumbnailsDirectory.path
        : DirectoryManager.instance.videoStillsDirectory.path;
    String thumPath = "$outputPath/${path.basename(vidPath)}-$timesStamp.png";
    return getFileName(thumPath);
  }

  static Future<Image> getThumbnail(String vidPath, int timesStamp,
      {bool isThumbnail = false}) async {
    Directory directory = isThumbnail
        ? DirectoryManager.instance.videoThumbnailsDirectory
        : DirectoryManager.instance.videoStillsDirectory;

    String fileName = "${path.basename(vidPath)}-$timesStamp.png";
    String newFile = "${directory.path}/$fileName";

    List<String> existingFiles = await listFileNamesInDirectory(directory);

    if (existingFiles.contains(fileName)) {
      return Image.file(File(newFile));
    }
    try {
      String newPath = "${directory.path}/";
      String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: vidPath,
        thumbnailPath: newPath,
        imageFormat:
            ImageFormat.PNG, // You can use other formats like JPEG, etc.
        timeMs: timesStamp,
      );

      if (thumbPath != null) {
        // You can now load the image from the thumbnailPath and display it in your Flutter app.
        // For example, using the Image widget:
        File renamed = await File(thumbPath).rename(newFile);
        vidPath = newFile;
        return Image.file(renamed);
      }
    } catch (e) {
      appLogger.severe('Error generating thumbnail: $e');
    }
    // Return this to signfiy an error
    return Image.network(
        "https://media.istockphoto.com/id/1349592578/de/vektor/leeres-warnschild-und-vorfahrtsschild-an-einem-mast-vektorillustration.webp?s=2048x2048&w=is&k=20&c=zmhLi9Ot96KXUe1OLd3dGNYJk0KMZZBQl39iQf6lcMk=");
  }

  static void getMostRecentVideo() async {
    if (DirectoryManager.instance.videosDirectory.existsSync()) {
      List<FileSystemEntity> files =
          DirectoryManager.instance.videosDirectory.listSync();
      mostRecentVideoName = getFileNameForAWS(files.last.path);
      mostRecentVideoPath = files.last.path;
    }
  }

  static Future<List<String>> listFileNamesInDirectory(
      Directory directory) async {
    List<String> fileNames = [];

    // Get a list of files in the directory.
    final dir = Directory(directory.path);
    List<FileSystemEntity> files = dir.listSync();

    // Extract the file names.
    for (var file in files) {
      if (file is File) {
        fileNames.add(file.uri.pathSegments.last);
      }
    }

    return fileNames;
  }

  // AWS doesn't like certain characters being used, so they must be fixed
  // TODO: Get better logic
  static getFileNameForAWS(String filePath) {
    // Get the file name from the full file path
    String fileName = path.basename(filePath);

    String partOne = fileName.replaceAll(" ", "_");

    String partTwo = partOne.replaceAll(":", "_");

    if (('.'.allMatches(partTwo).length > 1)) {
      return partTwo.replaceFirst(".", "_");
    }

    return partTwo;
  }
}
