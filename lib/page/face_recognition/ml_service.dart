import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_auth_flutter/utils/local_db.dart';
import 'package:flutter/foundation.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;
import '../../../models/user.dart';
import '../../utils/utils.dart';
import 'image_converter.dart';

class MLService {
  late Interpreter interpreter;
  List? predictedArray;
  List<User>? users;
  MLService._();

  static MLService instant = MLService._();

  Future<User?> predict({required CameraImage cameraImage, required Face face, String? name}) async {
    if (users == null) return null;
    List input = _preProcess(cameraImage, face);
    input = input.reshape([1, 112, 112, 3]);

    List output = List.generate(1, (index) => List.filled(192, 0));

    // // await initializeInterpreter();

    interpreter.run(input, output);
    output = output.reshape([192]);

    predictedArray = List.from(output);

    if (name != null) {
      LocalDB.setUserDetails(User(name: name, array: predictedArray!));
      return null;
    } else {
      // List<User>? users = LocalDB.getUser();
      User? userSuccess;
      num distTemp = 2.0;
      // users.sort(
      //   (a, b) => b.name!.length.compareTo(a.name!.length),
      // );
      for (var element in users!) {
        List userArray = element.array!;
        int minDist = 999;
        // double threshold = 1.5;
        double threshold = 0.7;
        var dist = await euclideanDistance(predictedArray!, userArray);
        debugPrint("threshold: $threshold");
        debugPrint("minDist: $minDist");
        debugPrint("dist: $dist");
        if (dist <= threshold && dist < minDist) {
          if (distTemp != dist && distTemp > dist) {
            distTemp = dist;
            userSuccess = element;
          }
          // return element;
        }
        // else {
        //   // return null;
        // }
      }
      return userSuccess;
    }
  }

  Future<num> euclideanDistance(List l1, List l2) async {
    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }

    return pow(sum, 0.5);
  }

  Future initializeInterpreter() async {
    Delegate? delegate;
    try {
      users = LocalDB.getUser();
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
          isPrecisionLossAllowed: false,
          inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
          inferencePriority1: TfLiteGpuInferencePriority.minLatency,
          inferencePriority2: TfLiteGpuInferencePriority.auto,
          inferencePriority3: TfLiteGpuInferencePriority.auto,
        ));
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(allowPrecisionLoss: true, waitType: TFLGpuDelegateWaitType.active),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate!);

      interpreter = await Interpreter.fromAsset('mobilefacenet.tflite', options: interpreterOptions);
    } catch (e) {
      printIfDebug('Failed to load model.');
      printIfDebug(e);
    }
  }

  List _preProcess(CameraImage image, Face faceDetected) {
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    Float32List imageAsList = _imageToByteListFloat32(img);
    return imageAsList;
  }

  imglib.Image _cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    var img = convertToImage(image);
    var img1 = imglib.copyRotate(img!, -90);
    return img1;
  }

  Float32List _imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
}
