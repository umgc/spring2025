// Author: David Bright
// Date: 2023-10-25
// Description: These classes are used to individually access the responses
//              in the AWS Rekognition Custom Label Response
// Last modified by: Ben Sutter
// Last modified on: 2023-11-03

import 'package:flutter/material.dart';

//class to work with the Custom Label Response from AWS Rekognition.
class CustomLabelResponse {
  String name;
  double confidence;
  ResponseBoundingBox? boundingBox;
  Image exampleImage =
      const Image(image: AssetImage("assets/test_images/eyeglass-green.jpg"));

  CustomLabelResponse(this.name, this.confidence);

  CustomLabelResponse.overloaded(this.name, this.confidence, this.boundingBox);
}

//class for the bounding box information in the Response object.
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
