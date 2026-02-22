import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../ml/ml_service.dart';
import '../services/api_service.dart';

class StudentExamScreen extends StatefulWidget {
  final int studentId;
  final int examId;
  const StudentExamScreen(
      {Key? key, required this.studentId, required this.examId})
      : super(key: key);

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  MLService? _mlService;
  List<CameraDescription>? _cameras;
  int _violationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enforceFullscreen();
    _initCamera();
  }

  void _enforceFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _cameraController =
        CameraController(_cameras!.first, ResolutionPreset.medium);
    await _cameraController!.initialize();
    _mlService = MLService(onViolation: _onViolation);
    _mlService!
        .startMonitoring(_cameraController!, widget.studentId, widget.examId);
    setState(() {});
  }

  void _onViolation(String violationType) {
    setState(() {
      _violationCount++;
    });
    if (_violationCount >= 3) {
      _autoSubmitExam();
    }
  }

  void _autoSubmitExam() {
    // Implement exam submission logic here
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Exam Auto-Submitted'),
        content: Text('You have reached the violation limit.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ApiService().sendFlag({
        'student_id': widget.studentId,
        'exam_id': widget.examId,
        'violation_type': 'app_minimized',
        'confidence': 1.0,
        'screenshot': '',
        'resolved': false,
      });
      _onViolation('app_minimized');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mlService?.stopMonitoring();
    _cameraController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: Text('Exam Monitoring')),
        body:
            _cameraController == null || !_cameraController!.value.isInitialized
                ? Center(child: CircularProgressIndicator())
                : CameraPreview(_cameraController!),
      ),
    );
  }
}
