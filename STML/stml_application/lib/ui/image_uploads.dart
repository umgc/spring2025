// ignore_for_file: avoid_print, prefer_const_constructors

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadFromGallery extends StatefulWidget {
  const UploadFromGallery({super.key});

  @override
  State<UploadFromGallery> createState() => _UploadFromGalleryState();
}

class _UploadFromGalleryState extends State<UploadFromGallery> {
  File? _image;
  final imagePicker = ImagePicker();
  String? downloadURL;

  Future imagePickerMethod() async {
    final pick = await imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pick != null) {
        _image = File(pick.path);
      } else {
        showSnackBar("No File selected", Duration(milliseconds: 400));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF880E4F),
      appBar: AppBar(
        backgroundColor: const Color(0XFFE91E63),
        title: const Text("Upload Image "),
      ),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                    height: 500,
                    width: double.infinity,
                    child: Column(children: [
                      const Text(
                        "Upload Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0XFFC6FF00)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // the image that we wanted to upload
                                Expanded(
                                    child: _image == null
                                        ? const Center(
                                            child: Text("No image selected"))
                                        : Image.file(_image!)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                        onPressed: () {
                                          imagePickerMethod();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color(
                                              0XFFC6FF00), // Button text color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Square border
                                          ),
                                        ),
                                        child: const Text("Select Image")),
                                    ElevatedButton(
                                        onPressed: () {
                                          if (_image != null) {
                                            //   uploadImage(_image!);
                                            showSnackBar(
                                                "Image Uploaded Succesfully",
                                                Duration(milliseconds: 400));
                                          } else {
                                            showSnackBar("Select Image first",
                                                Duration(milliseconds: 400));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color(
                                              0XFFC6FF00), // Button text color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Square border
                                          ),
                                        ),
                                        child: const Text("Upload Image")),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ])))),
      ),
    );
  }

  showSnackBar(String snackText, Duration d) {
    final snackBar = SnackBar(content: Text(snackText), duration: d);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class FromCamera extends StatefulWidget {
  const FromCamera({super.key});

  @override
  State<FromCamera> createState() => _FromCameraState();
}

class _FromCameraState extends State<FromCamera> {
  File? _image;
  final imagePicker = ImagePicker();
  String? downloadURL;

  Future imagePickerMethod() async {
    final pick = await imagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pick != null) {
        _image = File(pick.path);
      } else {
        showSnackBar("No File selected", Duration(milliseconds: 400));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF880E4F),
      appBar: AppBar(
        backgroundColor: const Color(0XFFE91E63),
        title: const Text("Upload Image "),
      ),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: SizedBox(
                    height: 500,
                    width: double.infinity,
                    child: Column(children: [
                      const Text(
                        "Upload Image",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          width: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0XFFC6FF00)),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // the image that we wanted to upload
                                Expanded(
                                    child: _image == null
                                        ? const Center(
                                            child: Text("No image selected"))
                                        : Image.file(_image!)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                        onPressed: () {
                                          imagePickerMethod();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color(
                                              0XFFC6FF00), // Button text color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Square border
                                          ),
                                        ),
                                        child: const Text("Take Image")),
                                    ElevatedButton(
                                        onPressed: () {
                                          if (_image != null) {
                                            //   uploadImage(_image!);
                                            showSnackBar(
                                                "Image Uploaded Succesfully",
                                                Duration(milliseconds: 400));
                                          } else {
                                            showSnackBar("Select Image first",
                                                Duration(milliseconds: 400));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color(
                                              0XFFC6FF00), // Button text color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                10.0), // Square border
                                          ),
                                        ),
                                        child: const Text("Upload Image")),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ])))),
      ),
    );
  }

  showSnackBar(String snackText, Duration d) {
    final snackBar = SnackBar(content: Text(snackText), duration: d);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
