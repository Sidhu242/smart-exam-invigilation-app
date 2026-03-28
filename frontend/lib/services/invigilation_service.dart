import 'dart:async';
import 'base_service.dart';

enum ViolationType {
  noFace,
  multipleFaces,
  tabSwitch,
  fullscreenExit,
  appMinimized,
}

class InvigilationService {
  static final InvigilationService _instance = InvigilationService._internal();

  final BaseService _baseService = BaseService();

  factory InvigilationService() => _instance;

  InvigilationService._internal();

  int _violationCount = 0;
  Timer? _faceCheckTimer;

  final int maxViolations = 2;

  Function()? onAutoSubmit;
  Function(int count)? onViolationUpdate;

  int get violationCount => _violationCount;

  // ============================
  // Start Monitoring
  // ============================

  void startMonitoring() {
    _violationCount = 0;
  }

  void stopMonitoring() {
    _faceCheckTimer?.cancel();
  }

  // ============================
  // MAIN VIOLATION METHOD
  // ============================

  Future<void> registerViolation(
    ViolationType type,
    String examId,
    String studentId,
  ) async {
    _violationCount++;

    print("Violation detected: $type");
    print("Total violations: $_violationCount");
    print("🚨 registerViolation called with type: $type");

    // Notify UI
    if (onViolationUpdate != null) {
      onViolationUpdate!(_violationCount);
    }

    // Send to backend
    await _sendViolationToBackend(type, examId, studentId);
  }

  // ============================
  // Backend Logging
  // ============================

  Future<void> _sendViolationToBackend(
    ViolationType type,
    String examId,
    String studentId,
  ) async {
    try {
      print("🔥 Sending violation to backend...");

      final response = await _baseService.post(
        "/log_violation",
        body: {
          "student_id": studentId,
          "exam_id": examId,
          "violation_type": type.name,
          "confidence": 1.0,
          "screenshot": "",
        },
      );

      print("✅ Backend response: $response");
    } catch (e) {
      print("❌ Violation log error: $e");
    }
  }
}
