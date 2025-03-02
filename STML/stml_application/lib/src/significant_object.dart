// Author: Ben Sutter
// Date: 2023-10-6
// Description: This class represents a user's significant object
// Last modified by: Ben Sutter
// Last modified on: 2023-11-04

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignificantObject {
  String identifier;
  List<Image> referencePhotos;
  List<String> alternateNames;
  List<ResponseBoundingBox> boundingBoxes = [];

  SignificantObject(this.identifier, this.referencePhotos, this.alternateNames);
  //assumption that images in referencePhotos map 1:1 to entries in boundingPhotos
  //i.e., the first Image in referencePhotos is associated with the first ResponseBoundingBox in boundingBoxes and so forth
  SignificantObject.overloaded(this.identifier, this.referencePhotos,
      this.alternateNames, this.boundingBoxes);

  deleteAlternateName(String nameToRemove) {
    alternateNames.remove(nameToRemove);
  }

  addAlternateName(String newName) {
    alternateNames.add(newName);
  }

  updateSignificantObject(
      Image image, String alternativeName, ResponseBoundingBox boundingBox) {
    referencePhotos.add(image);
    addAlternateName(alternativeName);
    boundingBoxes.add(boundingBox);
  }

  //create a manifest file for training of the custom label model in AWS Rekognition
  String generateRekognitionManifest() {
    String bar = "";
    int i = 0;
    // ignore: unused_local_variable
    for (Image im in referencePhotos) {
      ResponseBoundingBox annotation = boundingBoxes[i];
      String foo =
          '''{"source-ref": "s3://${dotenv.get('videoS3Bucket')}/$identifier-$i.jpg", "bounding-box": {"image_size": [{"width": 400, "height": 700, "depth": 3}], "annotations": [{ "class_id": 0,"top": ${(annotation.top * 700).toInt()}, "left": ${(annotation.left * 400).toInt()}, "width": ${(annotation.width * 400).toInt()}, "height": ${(annotation.height * 700).toInt()}}]},"bounding-box-metadata": {"objects": [{"confidence": 1}], "class-map": {"0": "$identifier"}, "type":"groundtruth/object-detection", "human-annotated": "yes", "creation-date": "2013-11-18T02:53:27"}}
  {"source-ref": "s3://${dotenv.get('videoS3Bucket')}/$identifier-$i-test.jpg", "bounding-box": {"image_size": [{"width": 400, "height": 700, "depth": 3}], "annotations": [{ "class_id": 0,"top": ${(annotation.top * 700).toInt()}, "left": ${(annotation.left * 400).toInt()}, "width": ${(annotation.width * 400).toInt()}, "height": ${(annotation.height * 700).toInt()}}]},"bounding-box-metadata": {"objects": [{"confidence": 1}], "class-map": {"0": "$identifier"}, "type":"groundtruth/object-detection", "human-annotated": "yes", "creation-date": "2013-11-18T02:53:27"}}''';
      bar += foo;
    }
    return bar;
  }
}

// The response bounding box is the overlay for the image to highlight it
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
