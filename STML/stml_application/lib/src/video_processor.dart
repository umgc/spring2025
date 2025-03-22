// Author: David Bright
// Date: 2023-10-06
// Description: Class for working with the AWS Rekognition API
// Last modified by: Ben Sutter
// Last modified on: 2023-11-04

import 'dart:core';
import 'dart:io';

import 'package:aws_rekognition_api/rekognition-2016-06-27.dart';
import 'package:memoryminder/src/aws_video_response.dart';
import 'package:memoryminder/src/data_service.dart';
import 'package:memoryminder/src/s3_connection.dart';
import 'package:memoryminder/src/utils/file_manager.dart';
import 'package:memoryminder/src/utils/format_utils.dart';
import 'package:memoryminder/src/utils/logger.dart';
import 'package:collection/collection.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VideoProcessor {
  //confidence setting for AWS Rekognition label detection service
  //(default is 50; the higher the more confident - and thus better and fewer results)
  double confidence = 85;
  Rekognition? service;
  //current video job being processed
  String jobId = '';
  //projectARN for the custom label project
  String projectArn = 'No project found';
  //"versionARN" or the model for a custom label
  String currentProjectVersionArn = 'Model not started';
  //custom label models that have successfully been trained
  List<String> availableModels = [];
  //custom label models that are currently running
  List<String> activeModels = [];
  String videoTitle = "";
  String address = "";
  String videoPath = "";

  Stopwatch stopwatch = Stopwatch();

  //exclusionary list to filter the responses shown to user.
  List<String> excludedResponses = [
    "Male",
    "Adult",
    "Man",
    "Female",
    "Woman",
    "Person",
    "Baby", //VERY IMPORTANT!!! DO NOT DELETE!!!
    "Bride",
    "Groom",
    "Girl",
    "Boy",
    "People",
    "Pet",
    "Animal",
    "Dog",
    "Cat",
    "Building",
    "Furniture"
  ];

  VideoProcessor() {
    FormatUtils.logBigMessage("Starting to process another video");
  }

  String getElapsedTimeInSeconds() {
    final seconds = stopwatch.elapsedMilliseconds / 1000.0;
    return 'Elapsed time: ${seconds.toStringAsFixed(2)} seconds';
  }

  //connect to the Rekognition service
  Future<void> startService() async {
    await dotenv.load(fileName: ".env"); //load .env file variables

    //pull values from the local .env file
    String region = (dotenv.get('region', fallback: "none"));
    String access = (dotenv.get('accessKey', fallback: "none"));
    String secret = (dotenv.get('secretKey', fallback: "none"));

    if (region == "none" || access == "none" || secret == "none") {
      appLogger.severe("AWS client access needs to be initialized");
      return;
    }

    //establish AWS Rekognition connection
    service = Rekognition(
        region: region,
        credentials:
            AwsClientCredentials(accessKey: access, secretKey: secret));

    //connect to Custom Label detection
    createProject();
    appLogger.info("Rekognition is up...");
  }

  Future<void> automaticallySendToRekognition() async {
    await startService();

    stopwatch.reset();
    stopwatch.start();
    await uploadVideoToS3();

    await pollForCompletedRequest();

    GetLabelDetectionResponse labelResponses = await grabResults(jobId);

    List<AWSVideoResponse> responses = createResponseList(labelResponses);

    await DataService.instance.addVideoResponses(responses);
    FormatUtils.logBigMessage("Rekognition results saved locally.");
    FormatUtils.logBigMessage(" Time elapsed ${getElapsedTimeInSeconds()}");
  }

  Future<StartLabelDetectionResponse> sendRequestToProcessVideo(
      String title) async {
    appLogger.info("sending rekognition request for $title");
    //grab Video
    Video video = Video(
        s3Object: S3Object(bucket: dotenv.get('videoS3Bucket'), name: title));
    //start label detection service of Video
    //The label detection operation is started by a call to StartLabelDetection which returns a job identifier
    Future<StartLabelDetectionResponse> job = service!.startLabelDetection(
      video: video,
      minConfidence: confidence,
    );
    //set the jobId, but return the whole job.
    job.then((value) {
      jobId = value.jobId!;
      appLogger.info("Job ID IS $jobId");
    });
    return job;
  }

  List<AWSVideoResponse> createTestResponseList() {
    return [
      AWSVideoResponse.overloaded(
          'Fish',
          90.63278198242188,
          53353,
          ResponseBoundingBox(
              left: 0.11934830248355865,
              top: 0.7510809302330017,
              width: 0.05737469345331192,
              height: 0.055630747228860855),
          "2023-10-27_12:19:21.819024.mp4",
          "3501 University Boulevard East, Adelphi, Maryland, 20783, US",
          "People, Person"),
      // Add more test objects for other URLs as needed
      /* AWS_VideoResponse('Water', 100, 52852, "fake file"),
         AWS_VideoResponse('Aerial View', 96.13745880126953, 53353, "fake file"),
         AWS_VideoResponse('Animal', 86.5937728881836, 53353, "fake file"),
         AWS_VideoResponse('Coast', 99.99983215332031, 53353, "fake file"), */
    ];
  }

  String getParentStringRepresentation(List<Parent> parents) {
    if (parents.isEmpty) {
      return "";
    }

    return parents.map((parent) => parent.name).join(', ');
  }

  List<String?> getParentNames(List<Parent> parents) {
    // Use map to extract parent names into a list.
    return parents.map((parent) => parent.name).toList();
  }

  bool stringListsHaveCommonElements(List<String> list1, List<String> list2) {
    // Use the `any` method to check if any element in list1 is also in list2.
    return list1.any((element) => list2.contains(element));
  }

  List<AWSVideoResponse> createResponseList(
      GetLabelDetectionResponse response) {
    FormatUtils.logBigMessage("CREATING RESPONSE LIST");
    List<AWSVideoResponse> responseList = [];

    Iterator<LabelDetection> iter = response.labels!.iterator;
    appLogger.info("ABOUT TO START PARSING RESPONSES");
    while (iter.moveNext()) {
      for (Instance inst in iter.current.label!.instances!) {
        String? name = iter.current.label!.name;

        // If a name is excluded, go to next loop
        if (excludedResponses.contains(name)) {
          continue;
        }

        // Create a list from the parents (if there are any easily exclude them)
        List<String> parents = getParentNames(iter.current.label!.parents ?? [])
            .whereNotNull()
            .toList();

        // If a name was not excluded but it has excluded parents then go to next loop
        if (stringListsHaveCommonElements(excludedResponses, parents)) {
          continue;
        }

        AWSVideoResponse newResponse = AWSVideoResponse.overloaded(
            iter.current.label!.name ?? "default value",
            iter.current.label!.confidence ?? 80,
            iter.current.timestamp ?? 0,
            ResponseBoundingBox(
                left: inst.boundingBox!.left ?? 0,
                top: inst.boundingBox!.top ?? 0,
                width: inst.boundingBox!.width ?? 0,
                height: inst.boundingBox!.height ?? 0),
            videoPath,
            address,
            getParentStringRepresentation(iter.current.label!.parents ?? []));
        responseList.add(newResponse);
      }
    }

    FormatUtils.logBigMessage("RESPONSE LIST WAS CREATED");

    return responseList;
  }

  //Rekognition jobs take a little while to process (sometimes 17s for a 60s clip)
  //this method checks for the most recent jobId, and when it completes, returns that the responses are ready to pull
  //(the jobId is returned, but that returned value signals that the responses are ready to pull)
  Future<String> pollForCompletedRequest() async {
    FormatUtils.logBigMessage("POLLING FOR COMPLETED REQUEST");
    //keep polling the getLabelDetection until either failed or succeeded.
    bool inProgress = true;
    while (inProgress) {
      FormatUtils.logBigMessage("STILL POLLING ${getElapsedTimeInSeconds()}");
      GetLabelDetectionResponse labelsResponse =
          await service!.getLabelDetection(jobId: jobId);
      //a little sleep thrown in here to limit the number of requests.
      sleep(const Duration(milliseconds: 5000));
      if (labelsResponse.jobStatus == VideoJobStatus.succeeded) {
        //stop looping
        inProgress = false;
      } else if (labelsResponse.jobStatus == VideoJobStatus.failed) {
        //stop looping, but log error message.
        inProgress = false;
        appLogger.info(labelsResponse.statusMessage);
      }
    }
    FormatUtils.logBigMessage("POLLING WAS COMPLETED JOB ID $jobId");
    return jobId;
  }

  Future<GetLabelDetectionResponse> grabResults(jobId) async {
    FormatUtils.logBigMessage("GRABBING RESULTS");

    //get a specific job in debuggin
    Future<GetLabelDetectionResponse> labelsResponse =
        service!.getLabelDetection(jobId: jobId);

    FormatUtils.logBigMessage("RESULTS GRABBED");
    return labelsResponse;
  }

  Future<void> uploadVideoToS3() async {
    FormatUtils.logBigMessage("UPLOADING VIDEO TO S3");
    S3Service s3 = S3Service();
    // Set the name for the file to be added to the bucket based on the file name
    FileManager.getMostRecentVideo();
    videoTitle = FileManager.mostRecentVideoName;
    videoPath = FileManager.mostRecentVideoPath;

    appLogger.info("Video title to S3: $videoTitle");
    appLogger.info("Video file path uploading to S3: $videoPath");

    String uploadedVideo = await s3.addVideoToS3(videoTitle, videoPath);

    await sendRequestToProcessVideo(uploadedVideo);

    FormatUtils.logBigMessage("VIDEO WAS UPLOADED");
  }

  //create a new Amazon Rekognition Custom Labels project
  //checks if one exists, and if so, sets that projectARN as the current projectArn
  //if one does not exists, creates one and set that projectARN as the current projectArn for later polling.
  void createProject() {
    String projectName = "cogni-open";
    bool projectDoesNotExists = true;
    Future<DescribeProjectsResponse> checkForProject =
        service!.describeProjects();

    checkForProject.then((value) {
      Iterator<ProjectDescription> iter = value.projectDescriptions!.iterator;
      while (iter.moveNext()) {
        if (iter.current.projectArn!.contains(projectName)) {
          projectDoesNotExists = false;
          projectArn = iter.current.projectArn!;
        }
      }

      if (projectDoesNotExists) {
        Future<CreateProjectResponse> projectResponse =
            service!.createProject(projectName: projectName);
        projectResponse.then((value) {
          projectArn = value.projectArn!;
        });
      }
    });
  }

  //needs a modelName ("my-glasses"), and the title of the input manifest file in S3 bucket
  void addNewModel(String modelName, String title) {
    List<Asset> assets = [];
    //Asset is a manifest file (that has the s3 images and bounding box information)
    Asset sigObj = Asset(
        groundTruthManifest: GroundTruthManifest(
            s3Object:
                S3Object(bucket: dotenv.get('videoS3Bucket'), name: title)));
    assets.add(sigObj);

    service!.createProjectVersion(
        outputConfig: OutputConfig(
            s3Bucket: dotenv.get('videoS3Bucket'),
            //dumps files from the model process(es) into a new folder
            s3KeyPrefix: "custom-labels"),
        projectArn: projectArn,
        testingData: TestingData(autoCreate: true),
        trainingData: TrainingData(assets: assets),
        versionName: modelName);
  }

  //adds all stopped or trained models to list of available models
  //deletes models that failed training
  Future<void> pollVersionDescription() async {
    Future<DescribeProjectVersionsResponse> projectVersions =
        service!.describeProjectVersions(projectArn: projectArn);
    availableModels.clear();
    projectVersions.then((value) {
      Iterator<ProjectVersionDescription> iter =
          value.projectVersionDescriptions!.iterator;
      while (iter.moveNext()) {
        //deletes a model if it failed training
        if (iter.current.status == ProjectVersionStatus.trainingFailed) {
          service!.deleteProjectVersion(
            projectVersionArn: iter.current.projectVersionArn!,
          );
        } else if ((iter.current.status == ProjectVersionStatus.stopped) ||
            (iter.current.status == ProjectVersionStatus.trainingCompleted)) {
          //where 9 is the lenght of "/version/"
          int substringStartingIndex =
              iter.current.projectVersionArn!.indexOf('/version/') + 9;
          String parsedName =
              iter.current.projectVersionArn!.substring(substringStartingIndex);
          parsedName = parsedName.split("/")[0];
          availableModels.add(parsedName);
        }
      }
    });
  }

  //check if the requested model (filter to find those of like name) has completed training.
  ProjectVersionStatus? pollForTrainedModel(String labelName) {
    Future<DescribeProjectVersionsResponse> projectVersions =
        service!.describeProjectVersions(projectArn: projectArn);
    projectVersions.then((value) {
      Iterator<ProjectVersionDescription> iter =
          value.projectVersionDescriptions!.iterator;
      while (iter.moveNext()) {
        if (iter.current.projectVersionArn!.contains(labelName)) {
          appLogger.info(
              "${iter.current.projectVersionArn} is ${iter.current.status}");
          return iter.current.status;
        }
      }
    });
    return ProjectVersionStatus.failed;
  }

  //start the inference of custom labels
  //can return a null if no such label is found (or if it failed training)
  String? startCustomDetection(String labelName) {
    //given an object label, check that the version is ready (i.e., trained)
    String? modelArn;
    //get all models in the project
    Future<DescribeProjectVersionsResponse> projectVersions =
        service!.describeProjectVersions(projectArn: projectArn);
    projectVersions.then((value) async {
      Iterator<ProjectVersionDescription> iter =
          value.projectVersionDescriptions!.iterator;
      while (iter.moveNext()) {
        //find model like the label name
        if (iter.current.projectVersionArn!.contains(labelName)) {
          //check that the model is either trained or stopped
          if (iter.current.status == ProjectVersionStatus.trainingCompleted ||
              iter.current.status == ProjectVersionStatus.stopped) {
            //start the model
            StartProjectVersionResponse response = await service!
                .startProjectVersion(
                    minInferenceUnits: 1,
                    projectVersionArn: iter.current.projectVersionArn!);
            appLogger.info(response.status);
            //returns the modelArn of the projectVersion being started
            //still need to poll the that the model has started
            activeModels.add(labelName);
            return iter.current.projectVersionArn;
          }
        }
      }
    });
    return modelArn;
  }

  //stop the inference of custom labels
  String? stopCustomDetection(String labelName) {
    String? modelArn;
    //given an object label, check that the version is ready (i.e., trained)
    //get all models in the project
    Future<DescribeProjectVersionsResponse> projectVersions =
        service!.describeProjectVersions(projectArn: projectArn);
    projectVersions.then((value) async {
      Iterator<ProjectVersionDescription> iter =
          value.projectVersionDescriptions!.iterator;
      while (iter.moveNext()) {
        //find model like the label name
        if (iter.current.projectVersionArn!.contains(labelName)) {
          //check that the model is running
          if (iter.current.status == ProjectVersionStatus.running) {
            //stop the model
            StopProjectVersionResponse response = await service!
                .stopProjectVersion(
                    projectVersionArn: iter.current.projectVersionArn!);
            appLogger.info(response.status);
            //returns the modelArn of the projectVersion being stopped
            //still need to poll the that the model has finished stopping
            return iter.current.projectVersionArn;
          }
        }
      }
    });
    return modelArn;
  }

  // When I wrote this, only God and I understood what I was doing
  // Now only God knows.
  // run Rekognition custom label detection on a specified set of images
  // ignore: body_might_complete_normally_nullable
  Future<DetectCustomLabelsResponse?> findMatchingModel(
      String labelName, String fileName) async {
    //look for a similar project version (model to match the label from the user)
    DescribeProjectVersionsResponse projectVersions =
        await service!.describeProjectVersions(projectArn: projectArn);
    bool search = true;
    //get together list of images to check against
    Iterator<ProjectVersionDescription> iter =
        projectVersions.projectVersionDescriptions!.iterator;
    while (iter.moveNext() & search) {
      //find model like the label name
      if (iter.current.projectVersionArn!.contains(labelName)) {
        //run the search for custom labels
        currentProjectVersionArn = iter.current.projectVersionArn!;
        search = false;
        return service!.detectCustomLabels(
            image: Image(
                s3Object: S3Object(
                    bucket: dotenv.get('videoS3Bucket'), name: fileName)),
            projectVersionArn: currentProjectVersionArn);
      }
    }
    if (search) {
      return null;
    }
    //Don't do this or it will throw null exception from the called reference
    //return null;
  }
}
