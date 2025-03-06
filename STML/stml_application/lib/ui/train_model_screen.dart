// Author: David Bright
// Date: 2023-10-13
// Description: Screen to allow user to save a response result as a significant object
//              and to allow saved response to train an AWS custom label model inside the Rekognition project
// Last modified by: Ben Sutter
// Last modified on: 2023-11-04

import 'package:memoryminder/src/database/model/video_response.dart';
import 'package:memoryminder/src/response_parser.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:memoryminder/src/significant_object.dart';
import 'package:memoryminder/src/utils/directory_manager.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/video_processor.dart';
import 'package:flutter/material.dart';

class ModelScreen extends StatefulWidget {
  final VideoResponse response;
  const ModelScreen(this.response, {super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn from User\'s choice'),
      ),
    );
  }

  @override
  // ignore: no_logic_in_create_state
  ModelScreenState createState() => ModelScreenState(response);
}

class ModelScreenState extends State<ModelScreen> {
  S3Bucket s3 = S3Bucket();
  VideoProcessor vp = VideoProcessor();
  VideoResponse response;

  String userDefinedModelName = '';

  ModelScreenState(this.response);

  @override
  Widget build(BuildContext context) {
    vp.startService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remember an object'),
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              16.0, 16.0, 16.0, 4.0), // Adjust padding as needed
          child: Text(
            'Welcome!', // This is the header text
            style: TextStyle(
              fontSize: 24.0, // Adjust font size as needed
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Padding(
          // New subheading section starts here
          padding: EdgeInsets.fromLTRB(
              16.0, 4.0, 16.0, 4.0), // Adjust padding as needed
          child: Text(
            "What do you want to call this object?", // This is the subheading text
            style: TextStyle(
              fontSize: 16.0, // Adjust font size as needed
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    onChanged: (text) {
                      setState(() {
                        userDefinedModelName = text;
                      });
                    },
                    decoration: const InputDecoration(
                        labelText:
                            'Enter significant object custom label name.'),
                  ),
                ],
              )),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            if (userDefinedModelName.isNotEmpty) {
              //if spaces, replace with '-'
              userDefinedModelName =
                  userDefinedModelName.replaceAll(RegExp('\\s+'), '-');
              //save the passed through response Image data, boundingbox info, and the custom label name as a Significant Object.
              SignificantObject sigObj = await addResponseAsSignificantObject(
                  userDefinedModelName, response);

              //once sigObj is made, request manifest be generated and uploaded to S3
              await s3.addFileToS3("$userDefinedModelName.json",
                  sigObj.generateRekognitionManifest());

              //once manifest loaded, start model training
              vp.addNewModel(
                  userDefinedModelName, "$userDefinedModelName.json");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid object name'),
                ),
              );
            }
          },
          child: const Text('Train Model'),
        ),
      ]),
    );
  }

  //converts the user selected VideoResponse into a SignificantObject, but also prepares SignificantObject for model training
  Future<SignificantObject> addResponseAsSignificantObject(
      String userDefinedModelName, VideoResponse response) async {
    // 1) pull information from resposne
    Image stillImage = await ResponseParser.getThumbnail(response);
    String filepath = FileManager.getThumbnailFileName(
        response.referenceVideoFilePath, response.timestamp);
    String path =
        "${DirectoryManager.instance.videoStillsDirectory.path}/$filepath";

    int i = 0;
    String name = response.title;
    ResponseBoundingBox boundingBox = ResponseBoundingBox(
        left: response.left,
        top: response.top,
        width: response.width,
        height: response.height);
    // 2) upload training/testing images to S3
    await s3.addImageToS3("$userDefinedModelName-$i.jpg", path);
    await s3.addImageToS3("$userDefinedModelName-$i-test.jpg", path);

    List<Image> images = [];
    images.add(stillImage);
    List<String> alternateNames = [];
    alternateNames.add(name);
    List<ResponseBoundingBox> boundingBoxes = [];
    boundingBoxes.add(boundingBox);
    // 3) transform to Significant Object
    SignificantObject sigObj = SignificantObject.overloaded(
        userDefinedModelName, images, alternateNames, boundingBoxes);

    return sigObj;
  }
}
