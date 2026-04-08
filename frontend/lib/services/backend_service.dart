import 'dart:typed_data';
import '../config/constants.dart';
import 'base_service.dart';
import '../utlis/exceptions.dart';

class BackendService {
  static final BackendService _instance = BackendService._internal();
  final BaseService _baseService = BaseService();

  factory BackendService() => _instance;

  BackendService._internal();

  /// Check frame from camera for proctoring
  /// Returns warning message if any suspicious activity detected
  static Future<String?> checkFrame(
    String studentName,
    String examId,
    Uint8List frameBytes,
  ) async {
    try {
      // In a real implementation, this would send the frame to the backend
      // for analysis using ML/AI models
      // For now, returning null indicates no warning

      // Example: You would convert bytes to base64 and send to backend
      // final base64Frame = base64Encode(frameBytes);
      // final response = await _instance._baseService.post(
      //   '/check_frame',
      //   body: {
      //     'student_name': studentName,
      //     'exam_id': examId,
      //     'frame': base64Frame,
      //   },
      // );

      return null;
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: 'Failed to check frame: ${e.toString()}');
    }
  }

  /// Log tab switch event for proctoring
  static Future<void> logTabSwitch(
    String studentName,
    String examId,
  ) async {
    try {
      await BackendService._instance._baseService.post(
        AppConfig.LOG_TAB_SWITCH,
        body: {
          'student_name': studentName,
          'exam_id': examId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to log tab switch: ${e.toString()}');
    }
  }

  /// Get warnings for a student in an exam
  static Future<List<dynamic>> getWarnings(
    String studentName,
    String examId,
  ) async {
    try {
      final response = await BackendService._instance._baseService.get(
        '${AppConfig.GET_WARNINGS}?student_name=${Uri.encodeComponent(studentName)}&exam_id=${Uri.encodeComponent(examId)}',
      );

      if (response['success'] == true) {
        return response['data']['warnings'] ?? [];
      } else {
        throw DataException(message: response['message'] ?? 'Failed to fetch warnings');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
          message: 'Failed to get warnings: ${e.toString()}');
    }
  }
}
