// Author: Ben Sutter
// Description: This class is used to query video responses for display in the object search menu.
//              It is also used to convert any responses into a significant object for display in the settings menu

import 'dart:core';
import 'dart:io';

import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/database/model/video_response.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/format_utils.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:flutter/material.dart';

class ResponseParser {
  // Searches for a single response in the list that matches the title
  // It returns the most recent response that matches the title (if one is found)
  static VideoResponse? getRequestedResponse(String searchTitle) {
    for (int i = DataService.instance.responseList.length - 1; i >= 0; i--) {
      if (DataService.instance.responseList[i].title == searchTitle) {
        return DataService.instance.responseList[i];
      }
    }
    return null;
  }

  // Given a response, convert it into a significant object for local saving.
  static Future<void> convertResponseToLocalSignificantObject(
      VideoResponse response) async {
    String sourceFilePath =
        "${DirectoryManager.instance.videosDirectory.path}/${response.referenceVideoFilePath}";
    File sourceFile = File(sourceFilePath);

    if (await sourceFile.exists()) {
      String fileName =
          FileManager.getThumbnailFileName(sourceFilePath, response.timestamp);
      String fullPath =
          "${DirectoryManager.instance.videoStillsDirectory.path}/$fileName";
      File destinationFile = File(fullPath);

      DataService.instance.addSignificantObject(
          timestamp: response.timestamp,
          left: response.left,
          top: response.top,
          width: response.width,
          height: response.height,
          imageFile: destinationFile);
    } else {
      appLogger.severe("Source file does not exist: $sourceFilePath");
    }
  }

  // Given a search title, return the list of all responses that match that title (recent first
  // The filter interval allows for extra filtering (only show results greater than the interval)
  // For instance, if interval is 2000, it will show reponses 2 seconds apart (rather than the default 4 from Rekognition)
  static List<VideoResponse> getRequestedResponseList(String searchTitle,
      {int filterInterval = 0}) {
    List<VideoResponse> responses = [];
    String previousFile = "";
    int previousTimeStamp = 0;

    for (int i = DataService.instance.responseList.length - 1; i >= 0; i--) {
      VideoResponse response = DataService.instance.responseList[i];

      if (response.title == searchTitle) {
        if (filterInterval == 0) {
          // Do nothing, but skip the next else if
        } else if (previousFile == response.referenceVideoFilePath &&
            response.timestamp - previousTimeStamp > -filterInterval) {
          // Skip this response if the file is the same and the timestamp difference is less than the repeat interval.
          continue;
        }

        responses.add(DataService.instance.responseList[i]);

        // Update previousFile and previousTimeStamp for the next iteration.
        previousFile = response.referenceVideoFilePath;
        previousTimeStamp = response.timestamp;
      }
    }
    return responses;
  }

  // Gets a unique list of all responses (only showing the most recent, unique occurance)
  static List<VideoResponse> getListOfResponses() {
    List<String> trackedTitles = [];
    List<VideoResponse> responses = [];
    for (int i = DataService.instance.responseList.length - 1; i >= 0; i--) {
      String title = DataService.instance.responseList[i].title;
      if (!trackedTitles.contains(title)) {
        trackedTitles.add(title);
        responses.add(DataService.instance.responseList[i]);
      }
    }
    return responses;
  }

  // Creates a thumbnail for the associated response
  static Future<Image> getThumbnail(VideoResponse response) async {
    String fullPath =
        "${DirectoryManager.instance.videosDirectory.path}/${response.referenceVideoFilePath}";
    return await FileManager.getThumbnail(fullPath, response.timestamp);
  }

  // Shows the timestamp for the response
  static String getTimeStampFromResponse(VideoResponse response) {
    String fullPath =
        "${DirectoryManager.instance.videosDirectory.path}/${response.referenceVideoFilePath}";
    String time = FileManager.getFileTimestamp(fullPath);
    DateTime parsedDate = DateTime.parse(time);
    return FormatUtils.getDateString(
        parsedDate.add(Duration(milliseconds: response.timestamp)));
  }

  // Gets the hour representation of the timestamp
  static String getHoursFromResponse(VideoResponse response) {
    String fullPath =
        "${DirectoryManager.instance.videosDirectory.path}/${response.referenceVideoFilePath}";
    String time = FileManager.getFileTimestamp(fullPath);
    DateTime parsedDate = DateTime.parse(time);
    return FormatUtils.getTimeString(
        parsedDate.add(Duration(milliseconds: response.timestamp)));
  }
}
