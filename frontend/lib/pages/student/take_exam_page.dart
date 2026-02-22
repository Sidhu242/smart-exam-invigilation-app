import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/exam_service.dart';
import '../../services/submission_service.dart';
import '../../services/invigilation_service.dart';
import '../../widgets/exam_timer.dart';
import '../../widgets/permission_dialog.dart';
import '../../utlis/exceptions.dart';
import '../../config/constants.dart';
import '../../config/globals.dart';

class TakeExamPage extends StatefulWidget {
  final String examId;
  final String examName;
  final String studentId;

  const TakeExamPage({
    Key? key,
    required this.examId,
    required this.examName,
    required this.studentId,
  }) : super(key: key);

  @override
  State<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends State<TakeExamPage>
    with WidgetsBindingObserver {
  final _examService = ExamService();
  final _submissionService = SubmissionService();
  final _invigilationService = InvigilationService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _questions = [];
  Map<String, String> _answers = {};
  int _examDurationSeconds = 3600;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!kIsWeb) {
      // Show permission dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionDialog(
            onPermissionsGranted: () {
              _initializeExam();
            },
            onPermissionsDenied: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Camera and microphone access is required to take the exam.'),
                  backgroundColor: Colors.red,
                ),
              );
              context.pop();
            },
          ),
        );
      }
    } else {
      _initializeExam();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _invigilationService.stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _invigilationService.logTabSwitch(widget.examId, widget.studentId);
      _showWarning('Keep the app in focus during the exam!');
    }
  }

  Future<void> _initializeExam() async {
    try {
      final questions = await _examService.getQuestions(widget.examId);

      for (final q in questions) {
        _answers[q['id']] = '';
      }

      if (!kIsWeb) {
        await _initCamera();
      }

      _invigilationService.startMonitoring(widget.examId, widget.studentId);

      setState(() {
        _questions = List<Map<String, dynamic>>.from(questions);
        _isLoading = false;
      });
    } on AppException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        // Handle camera permission denial - just continue without camera
        debugPrint('Camera permission denied');
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.low,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera init failed: $e');
    }
  }

  Future<void> _saveAnswer(String questionId, String answer) async {
    setState(() => _answers[questionId] = answer);

    try {
      await _submissionService.submitAnswer(
        studentId: widget.studentId,
        examId: widget.examId,
        questionId: questionId,
        answerText: answer,
      );
    } catch (e) {
      print('Answer save failed: $e');
    }
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);

    try {
      await _submissionService.submitExam(
        studentId: widget.studentId,
        examId: widget.examId,
        answers: _answers,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.EXAM_SUBMITTED),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go(
            '/student_home?studentId=${Uri.encodeComponent(widget.studentId)}&studentName=${Uri.encodeComponent(GlobalState.userName)}');
      }
    } on AppException catch (e) {
      _showErrorDialog(e.message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _onTimerEnd() {
    _showWarning('Time\'s up! Auto-submitting...');
    Future.delayed(const Duration(seconds: 1), _submitExam);
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF673AB7),
          elevation: 0,
          title: const Text('Loading Exam...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF673AB7),
          elevation: 0,
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF673AB7),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cameraActive = !kIsWeb &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog before leaving exam
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Exam?'),
            content: const Text(
              'Are you sure you want to leave the exam? Your answers will not be saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return result ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF673AB7),
          elevation: 2,
          title: Text(
            widget.examName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: ExamTimer(
                  durationInSeconds: _examDurationSeconds,
                  onTimerEnd: _onTimerEnd,
                ),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, idx) {
                  final q = _questions[idx];
                  final qId = q['id'] as String;
                  final qType = q['question_type'] as String;
                  final qText = q['question_text'] as String;
                  final options = (q['options'] as List<dynamic>?)
                          ?.cast<String>()
                          .toList() ??
                      [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Q${idx + 1}: $qText',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (qType == 'mcq' && options.isNotEmpty)
                            ...options.map((opt) {
                              return RadioListTile<String>(
                                title: Text(opt),
                                value: opt,
                                groupValue: _answers[qId],
                                onChanged: (v) {
                                  if (v != null) _saveAnswer(qId, v);
                                },
                              );
                            })
                          else
                            TextField(
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Type your answer...',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (v) {
                                setState(() => _answers[qId] = v);
                              },
                              onSubmitted: (v) => _saveAnswer(qId, v),
                            ),
                          if ((_answers[qId] ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: const [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Saved',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (cameraActive)
              Container(
                width: 220,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          Icon(Icons.videocam,
                              size: 16, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Camera is monitored',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CameraPreview(_cameraController!),
                    ),
                  ],
                ),
              ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitExam,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.PRIMARY,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
