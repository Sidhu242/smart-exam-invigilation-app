import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

import '../ml/ml_service.dart';
import '../services/invigilation_service.dart';
import '../config/constants.dart';

class StudentExamScreen extends StatefulWidget {
  final int studentId;
  final int examId;

  const StudentExamScreen({
    Key? key,
    required this.studentId,
    required this.examId,
  }) : super(key: key);

  @override
  State<StudentExamScreen> createState() => _StudentExamScreenState();
}

class _StudentExamScreenState extends State<StudentExamScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  MLService? _mlService;
  List<CameraDescription>? _cameras;

  final InvigilationService _invigilationService = InvigilationService();

  int _violationCount = 0;

  // ==============================
  // INIT
  // ==============================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _enforceFullscreen();
    _initCamera();
    _setupInvigilation();
    _setupWebTabDetection();
  }

  // ==============================
  // INVIGILATION SETUP
  // ==============================

  void _setupInvigilation() {
    _invigilationService.startMonitoring();

    _invigilationService.onViolationUpdate = (count) {
      if (mounted && count > _violationCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning! Violation Detected ($count/2)'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _violationCount = count;
      });
    };

    _invigilationService.onAutoSubmit = () {
      _autoSubmitExam();
    };
  }

  // ==============================
  // FULLSCREEN ENFORCEMENT
  // ==============================

  void _enforceFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ==============================
  // CAMERA INIT
  // ==============================

  Future<void> _initCamera() async {
    _cameras = await availableCameras();

    _cameraController =
        CameraController(_cameras!.first, ResolutionPreset.medium);

    await _cameraController!.initialize();

    _mlService = MLService(
      onViolation: (violationType) {
        _handleMLViolation(violationType);
      },
    );

    _mlService!.startMonitoring(
      _cameraController!,
      widget.studentId,
      widget.examId,
    );

    setState(() {});
  }

  // ==============================
  // ML VIOLATIONS
  // ==============================

  void _handleMLViolation(String violationType) {
    ViolationType type;

    switch (violationType) {
      case "no_face":
        type = ViolationType.noFace;
        break;
      case "multiple_faces":
        type = ViolationType.multipleFaces;
        break;
      default:
        type = ViolationType.noFace;
    }

    _invigilationService.registerViolation(
      type,
      widget.examId.toString(),
      widget.studentId.toString(),
    );
  }

  // ==============================
  // WEB TAB SWITCH DETECTION
  // ==============================

  void _setupWebTabDetection() {
    // Tab detection removed to avoid dart:html dependency in universal build.
    // Can be implemented using WidgetsBindingObserver or other platform-specific ways.
  }

  // ==============================
  // AUTO SUBMIT
  // ==============================

  void _autoSubmitExam() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Exam Terminated"),
        content: const Text(
            "Too many violations detected. Exam has been auto-submitted."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  // ==============================
  // APP MINIMIZE DETECTION
  // ==============================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _invigilationService.registerViolation(
        ViolationType.appMinimized,
        widget.examId.toString(),
        widget.studentId.toString(),
      );
    }
  }

  // ==============================
  // DISPOSE
  // ==============================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mlService?.stopMonitoring();
    _cameraController?.dispose();
    _invigilationService.stopMonitoring();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  // ==============================
  // UI
  // ==============================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Exam Monitoring'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  "Violations: $_violationCount / ${InvigilationService().maxViolations}",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          ],
        ),
        body: Stack(
          children: [
            // Dummy content for the exam background
            Container(
              color: AppColors.BACKGROUND,
              child: const Center(
                child: Text(
                  'Exam Question Content Goes Here',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.TEXT_SECONDARY,
                  ),
                ),
              ),
            ),
            
            // Top Right Camera Preview Overlay
            Positioned(
              top: 16,
              right: 16,
              child: _cameraController == null || !_cameraController!.value.isInitialized
                  ? const SizedBox(
                      width: 120,
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 120,
                        height: 160,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
