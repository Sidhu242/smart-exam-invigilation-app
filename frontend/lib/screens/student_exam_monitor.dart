import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../ml/ml_service.dart';

class StudentExamMonitor extends StatefulWidget {
  final int studentId;
  final int examId;
  const StudentExamMonitor(
      {Key? key, required this.studentId, required this.examId})
      : super(key: key);

  @override
  State<StudentExamMonitor> createState() => _StudentExamMonitorState();
}

class _StudentExamMonitorState extends State<StudentExamMonitor> {
  CameraController? _cameraController;
  MLService? _mlService;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController =
        CameraController(_cameras!.first, ResolutionPreset.medium);
    await _cameraController!.initialize();
    _mlService = MLService(onViolation: (String p1) {});
    _mlService!
        .startMonitoring(_cameraController!, widget.studentId, widget.examId);
    setState(() {});
  }

  @override
  void dispose() {
    _mlService?.stopMonitoring();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exam Monitoring')),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? Center(child: CircularProgressIndicator())
          : CameraPreview(_cameraController!),
    );
  }
}
