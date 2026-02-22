import 'dart:async';
import 'base_service.dart';
import '../config/constants.dart';

class InvigilationService {
  static final InvigilationService _instance = InvigilationService._internal();
  final BaseService _baseService = BaseService();

  factory InvigilationService() => _instance;

  InvigilationService._internal();

  int _warningCount = 0;
  Timer? _statusTimer;

  int get warningCount => _warningCount;

  /// Start monitoring
  void startMonitoring(String examId, String studentId) {
    _warningCount = 0;
    _statusTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _checkStatus(examId, studentId);
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _statusTimer?.cancel();
  }

  /// Log tab switch
  Future<void> logTabSwitch(String examId, String studentId) async {
    try {
      await _baseService.post(
        AppConfig.LOG_TAB_SWITCH,
        body: {
          'exam_id': examId,
          'student_id': studentId,
        },
      );
      _warningCount++;
    } catch (e) {
      print('Tab switch log error: $e');
    }
  }

  /// Check status
  Future<void> _checkStatus(String examId, String studentId) async {
    try {
      final response = await _baseService.get(
        '${AppConfig.GET_WARNINGS}/$examId?student_id=$studentId',
      );

      if (response['warnings'] != null) {
        _warningCount = (response['warnings'] as List).length;
      }
    } catch (e) {
      // Silent fail
    }
  }
}
