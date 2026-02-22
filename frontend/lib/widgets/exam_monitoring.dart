import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/backend_service.dart';

class ExamMonitoringWidget extends StatefulWidget {
  final String studentName;
  final String examId;
  final Function(String) onWarning;

  const ExamMonitoringWidget({
    super.key,
    required this.studentName,
    required this.examId,
    required this.onWarning,
  });

  @override
  State<ExamMonitoringWidget> createState() => _ExamMonitoringWidgetState();
}

class _ExamMonitoringWidgetState extends State<ExamMonitoringWidget> {
  CameraController? _controller;
  Timer? _timer;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      _controller = CameraController(cameras![0], ResolutionPreset.low);
      await _controller!.initialize();
      setState(() {});

      // Start sending frames to backend every 5 seconds
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => sendFrame());
    }
  }

  Future<void> sendFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();
      final warning = await BackendService.checkFrame(
        widget.studentName,
        widget.examId,
        bytes,
      );

      if (warning != null && warning.isNotEmpty && mounted) {
        widget.onWarning(warning);
      }
    } catch (e) {
      debugPrint("Error sending frame: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_controller!);
  }
}
