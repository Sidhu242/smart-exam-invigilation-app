import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/api_service.dart';

class MLService {
  final void Function(String) onViolation;

  MLService({required this.onViolation});

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  final Map<String, DateTime> _lastViolation = {};
  Timer? _timer;
  CameraController? _cameraController;
  bool _eyesClosed = false;
  DateTime? _eyesClosedStart;

  void startMonitoring(
      CameraController cameraController, int studentId, int examId) {
    _cameraController = cameraController;

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_cameraController!.value.isInitialized) return;

      final frame = await _cameraController!.takePicture();
      final bytes = await frame.readAsBytes();
      final inputImage = InputImage.fromFilePath(frame.path);
      final faces = await _faceDetector.processImage(inputImage);

      String? violation;
      double confidence = 1.0;

      if (faces.isEmpty) {
        violation = 'no_face';
      } else if (faces.length > 1) {
        violation = 'multiple_faces';
      } else {
        final face = faces.first;

        if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 25) {
          violation = 'head_turned_side';
        } else if (face.headEulerAngleX != null && (face.headEulerAngleX! > 15 || face.headEulerAngleX! < -20)) {
          violation = 'head_turned_up_down';
        } else if (face.headEulerAngleZ != null && face.headEulerAngleZ!.abs() > 30) {
          violation = 'head_tilted';
        }

        if (face.leftEyeOpenProbability != null &&
            face.rightEyeOpenProbability != null) {
          final eyesClosed = (face.leftEyeOpenProbability! < 0.2 &&
              face.rightEyeOpenProbability! < 0.2);

          if (eyesClosed) {
            if (!_eyesClosed) {
              _eyesClosed = true;
              _eyesClosedStart = DateTime.now();
            } else if (_eyesClosedStart != null &&
                DateTime.now().difference(_eyesClosedStart!).inSeconds > 3) {
              violation = 'eyes_closed';
            }
          } else {
            _eyesClosed = false;
            _eyesClosedStart = null;
          }
        }
      }

      if (violation != null) {
        final now = DateTime.now();

        if (_lastViolation[violation] == null ||
            now.difference(_lastViolation[violation]!).inSeconds > 10) {
          _lastViolation[violation] = now;

          final base64Image = base64Encode(bytes);

          await ApiService().sendFlag({
            'student_id': studentId,
            'exam_id': examId,
            'violation_type': violation,
            'confidence': confidence,
            'screenshot': base64Image,
            'resolved': false,
          });

          // 🔥 THIS FIXES YOUR PROBLEM
          onViolation(violation);
        }
      }
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _cameraController = null;
    _eyesClosed = false;
    _eyesClosedStart = null;
  }
}
