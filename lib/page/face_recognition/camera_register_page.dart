import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_auth_flutter/main.dart';
import 'package:face_auth_flutter/page/face_recognition/camera_page.dart';
import 'package:face_auth_flutter/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';
import '../../models/user.dart';
import '../../widgets/common_widgets.dart';
import 'ml_service.dart';

class RegisterScreen extends StatefulWidget {
  // final User? user;
  final String? name;

  final XFile? fileRegister;

  const RegisterScreen({Key? key, this.fileRegister, this.name}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late CameraController _cameraController;
  bool flash = false;
  bool isControllerInitialized = false;
  late FaceDetector _faceDetector;
  // final MLService _mlService = MLService();
  List<Face> facesDetected = [];
  bool canProcess = false;

  Future initializeCamera() async {
    await _cameraController.initialize();
    MLService.instant.initializeInterpreter();
    isControllerInitialized = true;
    _cameraController.setFlashMode(FlashMode.off);
    setState(() {});
  }

  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.Rotation_90deg;
      case 180:
        return InputImageRotation.Rotation_180deg;
      case 270:
        return InputImageRotation.Rotation_270deg;
      default:
        return InputImageRotation.Rotation_0deg;
    }
  }

  Future<void> detectFacesFromImage(CameraImage image) async {
    InputImageData _firebaseImageMetadata = InputImageData(
      imageRotation: rotationIntToImageRotation(_cameraController.description.sensorOrientation),
      inputImageFormat: InputImageFormat.BGRA8888,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      planeData: image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList(),
    );

    InputImage _firebaseVisionImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      inputImageData: _firebaseImageMetadata,
    );
    var result = await _faceDetector.processImage(_firebaseVisionImage);
    if (result.isNotEmpty) {
      facesDetected = result;
    }
  }

  Future<void> _predictFacesFromImage({required CameraImage image}) async {
    await detectFacesFromImage(image);

    if (facesDetected.isNotEmpty) {
      User? user = await MLService.instant.predict(cameraImage: image, face: facesDetected[0], name: widget.name);
      if (widget.name != null) {
        // register case
        Navigator.pop(context);
        print("User registered successfully");
      } else {
        // login case
        if (user == null) {
          Navigator.pop(context);
          print("Unknown User");
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(
                        user: user,
                      )));
        }
      }
    }
    if (mounted) setState(() {});
    await takePicture();
  }

  Future<void> takePicture() async {
    if (facesDetected.isNotEmpty) {
      await _cameraController.stopImageStream();
      XFile file = await _cameraController.takePicture();
      file = XFile(file.path);
      _cameraController.setFlashMode(FlashMode.off);
    } else {
      // showDialog(
      //     context: context,
      //     builder: (context) =>
      //         const AlertDialog(content: Text('No face detected!')));
    }
  }

  @override
  void initState() {
    _cameraController = CameraController(cameras![1], ResolutionPreset.high);
    initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      const FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Register"),
        ),
        body: Stack(
          children: [
            widget.fileRegister != null
                ? Image.file(
                    File(widget.fileRegister!.path),
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    fit: BoxFit.contain,
                  )
                : SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: isControllerInitialized
                        ? CameraPreview(_cameraController)
                        : const Center(
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(),
                            ),
                          )),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Lottie.asset("assets/loading.json", width: MediaQuery.of(context).size.width * 0.7),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: CWidgets.customExtendedButton(
                            text: "Capture",
                            context: context,
                            isClickable: true,
                            onTap: () {
                              bool canProcess = false;
                              _cameraController.startImageStream((CameraImage image) async {
                                if (canProcess) return;
                                canProcess = true;
                                _predictFacesFromImage(image: image).then((value) {
                                  canProcess = false;
                                });
                                return null;
                              });
                            }),
                      ),
                      IconButton(
                          icon: Icon(
                            flash ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              flash = !flash;
                            });
                            flash ? _cameraController.setFlashMode(FlashMode.torch) : _cameraController.setFlashMode(FlashMode.off);
                          }),
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
