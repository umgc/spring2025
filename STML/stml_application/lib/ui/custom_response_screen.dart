// Author: David Bright
// Date: 2023-10-25
// Description: Display query results of custom label responses from AWS Rekognition
// Last modified by: David Bright
// Last modified on: 2023-11-05
import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as rek;
import 'package:memoryminder/src/custom_label_response.dart';
import 'package:flutter/material.dart';

//create a list of CustomLabelResponse objects from the DetectCustomLabelsResponse response
List<CustomLabelResponse> createResponseList(
    rek.DetectCustomLabelsResponse response) {
  List<CustomLabelResponse> responseList = [];
  List<String?> recognizedItems = [];

  //user Iterator to traverse response list
  Iterator<rek.CustomLabel> iter = response.customLabels!.iterator;
  while (iter.moveNext()) {
    String? name = iter.current.name;
    if (recognizedItems.contains(name)) {
      continue;
    } else {
      recognizedItems.add(name);
    }
    CustomLabelResponse newResponse = CustomLabelResponse.overloaded(
      iter.current.name ?? "default value",
      iter.current.confidence ?? 80,
      ResponseBoundingBox(
          left: iter.current.geometry!.boundingBox!.left ?? 0,
          top: iter.current.geometry!.boundingBox!.top ?? 0,
          width: iter.current.geometry!.boundingBox!.width ?? 0,
          height: iter.current.geometry!.boundingBox!.height ?? 0),
    );
    responseList.add(newResponse);
  }
  return responseList;
}

class CustomResponseScreen extends StatefulWidget {
  final rek.DetectCustomLabelsResponse awsResponses;
  //pass through the awsResponses from the query processing screen
  const CustomResponseScreen(this.awsResponses, {super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query Responses',
            style: TextStyle(color: Colors.black54)),
      ),
    );
  }

  @override
  CustomResponseScreenState createState() =>
      // ignore: no_logic_in_create_state
      CustomResponseScreenState(awsResponses);
}

class CustomResponseScreenState extends State<CustomResponseScreen> {
  rek.DetectCustomLabelsResponse awsResponses;
  CustomResponseScreenState(this.awsResponses);

  @override
  Widget build(BuildContext context) {
    List<CustomLabelResponse> realResponse = createResponseList(awsResponses);

    //hardcoded values from the test image; to be replaced with the response image information
    double imageWidth = 225;
    double imageHeight = 225;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Query Responses',
            style: TextStyle(color: Colors.black54)),
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              16.0, 16.0, 16.0, 4.0), // Adjust padding as needed
          child: Text(
            'Recent query responses',
            style: TextStyle(
              fontSize: 24.0, // Adjust font size as needed
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: realResponse.length,
            itemBuilder: (BuildContext context, int index) {
              CustomLabelResponse response = realResponse[index];
              return GestureDetector(
                onTap: () async {
                  //open new screen for full details of response result
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(
                            title:
                                const Text('Full Screen Response and Details'),
                          ),
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Image(image: response.exampleImage.image),
                                    Positioned(
                                      left: imageWidth *
                                          response.boundingBox!.left,
                                      top: imageHeight *
                                          response.boundingBox!.top,
                                      child: Opacity(
                                        opacity: 0.35,
                                        child: Material(
                                          child: InkWell(
                                            child: Container(
                                              width: imageWidth *
                                                  response.boundingBox!.width,
                                              height: imageHeight *
                                                  response.boundingBox!.height,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  width: 2,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  color: Colors.black,
                                                  child: Text(
                                                    '${response.name} ${((response.confidence * 100).truncateToDouble()) / 100}%',
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text('Name: ${response.name}',
                                    style: const TextStyle(fontSize: 18)),
                                Text(
                                    'BoundingBox: ${response.boundingBox?.toString() ?? "N/A"}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          response.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ]),
    );
  }
}
