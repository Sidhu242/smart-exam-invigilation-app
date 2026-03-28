import 'base_service.dart';
import '../config/constants.dart';
import '../utlis/exceptions.dart';

class SubmissionService {
  static final SubmissionService _instance = SubmissionService._internal();
  final BaseService _baseService = BaseService();

  factory SubmissionService() => _instance;

  SubmissionService._internal();

  /// Submit single answer
  Future<bool> submitAnswer({
    required String studentId,
    required String examId,
    required String questionId,
    required String answerText,
  }) async {
    try {
      final response = await _baseService.post(
        AppConfig.SUBMIT_ANSWER,
        body: {
          'student_id': studentId,
          'exam_id': examId,
          'question_id': questionId,
          'answer_text': answerText,
        },
      );

      return response['status'] == 'success';
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Submit entire exam
  Future<Map<String, dynamic>> submitExam({
    required String studentId,
    required String examId,
    required Map<String, String> answers,
  }) async {
    try {
      return await _baseService.post(
        AppConfig.SUBMIT_EXAM,
        body: {
          'student_id': studentId,
          'exam_id': examId,
          'answers': answers,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Get summary
  Future<Map<String, dynamic>> getSummary(String studentId) async {
    try {
      final response = await _baseService.get(
        '${AppConfig.GET_SUMMARY}/$studentId',
      );

      if (response['status'] == 'success') {
        return response['summary'] ?? {};
      } else {
        throw DataException(message: 'Failed to fetch summary');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Get results
  Future<List<dynamic>> getResults(String examId) async {
    try {
      final response = await _baseService.get(
        '${AppConfig.GET_EXAM_RESULTS}/$examId',
      );

      if (response['status'] == 'success') {
        return response['results'] ?? [];
      } else {
        throw DataException(message: 'Failed to fetch results');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Get violations
  Future<List<dynamic>> getViolations(String examId) async {
    try {
      final response = await _baseService.get(
        '/get_warnings/$examId',
      );

      if (response['status'] == 'success') {
        return response['warnings'] ?? [];
      } else {
        throw DataException(message: 'Failed to fetch violations');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }
}
