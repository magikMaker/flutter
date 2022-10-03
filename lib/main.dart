import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'camera.dart';
import 'painter.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ObjectDetector _objectDetector;
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Frontmania'),
        ),
        body: CameraView(
          camera: cameras[0],
          customPaint: _customPaint,
          onImage: (inputImage) {
            processImage(inputImage);
          },
        ),
      ),
    );
  }

  void _initializeDetector() async {
    final model = 'lite-model_object_detection_mobile_object_labeler_v1_1';
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.stream,
      modelPath: 'flutter_assets/assets/ml/$model.tflite',
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
    _canProcess = true;
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;

    _isBusy = true;
    final objects = await _objectDetector.processImage(inputImage);
    final painter = ObjectDetectorPainter(
        objects,
        inputImage.inputImageData!.imageRotation,
        inputImage.inputImageData!.size);
    _customPaint = CustomPaint(painter: painter);
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector.close();
    super.dispose();
  }
}