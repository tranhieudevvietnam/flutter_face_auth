import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:face_auth_flutter/main.dart';
import 'package:face_auth_flutter/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:lottie/lottie.dart';
import 'ml_service.dart';

class FaceScanScreen extends StatefulWidget {
  // final User? user;

  final XFile? fileRegister;

  const FaceScanScreen({
    Key? key,
    this.fileRegister,
  }) : super(key: key);

  @override
  _FaceScanScreenState createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen> {
  late CameraController _cameraController;
  bool flash = false;
  bool isControllerInitialized = false;
  late FaceDetector _faceDetector;
  // final MLService _mlService = MLService();
  List<Face> facesDetected = [];
  bool canProcess = false;

  Timer? _timer1;
  Timer? _timer2;

  Future initializeCamera() async {
    await _cameraController.initialize();
    isControllerInitialized = true;
    _cameraController.setFlashMode(FlashMode.off);
    setState(() {});
  }

  _startCamera() {
    _cameraController.startImageStream((CameraImage image) async {
      if (canProcess) return;
      canProcess = true;
      await _predictFacesFromImage(image: image);
      return null;
    });
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
    try {
      await detectFacesFromImage(image);

      if (facesDetected.isNotEmpty) {
        final user = await MLService.instant.predict(cameraImage: image, face: facesDetected[0]);
        debugPrint("=====> _predictFacesFromImage");

        if (user != null) {
          // debugPrint("xxxx: ${jsonEncode(user.toJson())}");
          takePicture();
          Navigator.of(context).pop();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HomePage(
                        user: user,
                      )));
        } else {
          canProcess = false;
        }
        // User? user = await MLService.instant.predict(cameraImage: image, face: facesDetected[0]);
        // // login case
        // if (user != null) {
        //   debugPrint("xxxx: ${jsonEncode(user.toJson())}");
        //   // takePicture();
        //   // Navigator.of(context).pop();
        //   // Navigator.push(
        //   //     context,
        //   //     MaterialPageRoute(
        //   //         builder: (context) => HomePage(
        //   //               user: user,
        //   //             )));
        // }
      }
      // if (mounted) setState(() {});
      // await takePicture();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> takePicture() async {
    if (facesDetected.isNotEmpty) {
      await _cameraController.stopImageStream();
      XFile file = await _cameraController.takePicture();
      file = XFile(file.path);
      // _cameraController.setFlashMode(FlashMode.off);
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
    _faceDetector = GoogleMlKit.vision.faceDetector(
      const FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _timer1 = Timer(const Duration(seconds: 1), () async {
        await initializeCamera();
        _timer2 = Timer(const Duration(seconds: 1), () async {
          await MLService.instant.initializeInterpreter();
          _startCamera();
        });
      });
    });
  }

  @override
  void dispose() {
    debugPrint("=====> dispose");
    _timer1?.cancel();
    _timer2?.cancel();
    _cameraController.stopImageStream();
    _cameraController.dispose();
    super.dispose();
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
          title: const Text("Login"),
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
                    child: Lottie.asset("assets/loading.json", width: MediaQuery.of(context).size.width),
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
