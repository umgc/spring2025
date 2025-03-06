// Author: David Bright
// Date: 2023-10-10
// Description: These classes are used to individually access the responses
//              in the AWS Rekognition Object Label Response
// Last modified by: Zach Bowman
// Last modified on: 2023-11-02

import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:flutter/material.dart';

class AWSVideoResponse {
  String name;
  double confidence;
  int timestamp;
  ResponseBoundingBox boundingBox;
  String referenceVideoFilePath;
  String address;
  String parents;

  Image exampleImage = Image.network(
      "https://cdn.pixabay.com/photo/2014/06/03/19/38/road-sign-361514_1280.png");

  AWSVideoResponse.overloaded(
      this.name,
      this.confidence,
      this.timestamp,
      this.boundingBox,
      this.referenceVideoFilePath,
      this.address,
      this.parents);

  //pull thumbnail image from the local file
  Future<Image> getImage() async {
    return await FileManager.getThumbnail(
        FileManager.mostRecentVideoPath, timestamp);
  }

  //reset thumbnail image with a new thumbnail from updated timestamp
  void setImage(int timeStampNew) async {
    exampleImage = await FileManager.getThumbnail(
        FileManager.mostRecentVideoPath, timeStampNew);
  }
}

//Bounding Box coordinates - in double percentage (i.e., 0.1 for left means 10% of the pixel width from the left side for the initial box coordinate)
class ResponseBoundingBox {
  double left;
  double top;
  double width;
  double height;

  ResponseBoundingBox(
      {required this.left,
      required this.top,
      required this.width,
      required this.height});

  @override
  String toString() {
    return 'ResponseBoundingBox{left: $left, top: $top, width: $width, height: $height}';
  }
}
