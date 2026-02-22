import 'base_service.dart';
import '../config/constants.dart';
import '../utlis/exceptions.dart';

class ExamService {
  static final ExamService _instance = ExamService._internal();
  final BaseService _baseService = BaseService();

  factory ExamService() => _instance;

  ExamService._internal();

  /// Get exams for institution
  Future<List<dynamic>> getExams({
    required String institution,
    bool published = true,
  }) async {
    try {
      final response = await _baseService.get(
        '${AppConfig.GET_EXAMS}?institution=${Uri.encodeComponent(institution)}&published=${published ? '1' : '0'}',
      );

      if (response['status'] == 'success') {
        return response['exams'] ?? [];
      } else {
        throw DataException(message: 'Failed to fetch exams');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Get questions for exam
  Future<List<dynamic>> getQuestions(String examId) async {
    if (examId.isEmpty) {
      throw ValidationException(message: 'Exam ID required');
    }

    try {
      final response = await _baseService.get(
        '${AppConfig.GET_QUESTIONS}/$examId',
      );

      if (response['status'] == 'success') {
        return response['questions'] ?? [];
      } else {
        throw DataException(message: AppStrings.EXAM_LOAD_FAILED);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Create exam
  Future<Map<String, dynamic>> createExam({
    required String id,
    required String name,
    required String dateTime,
    required String institution,
  }) async {
    try {
      return await _baseService.post(
        AppConfig.CREATE_EXAM,
        body: {
          'id': id,
          'name': name,
          'exam_datetime': dateTime,
          'institution': institution,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Publish exam
  Future<Map<String, dynamic>> publishExam(String examId) async {
    try {
      return await _baseService.post(
        AppConfig.PUBLISH_EXAM,
        body: {'exam_id': examId},
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Delete exam
  Future<Map<String, dynamic>> deleteExam(String examId) async {
    try {
      return await _baseService.delete('${AppConfig.DELETE_EXAM}/$examId');
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Add question
  Future<Map<String, dynamic>> addQuestion({
    required String id,
    required String examId,
    required String text,
    required String type,
    List<String>? options,
    String? correctAnswer,
  }) async {
    try {
      return await _baseService.post(
        AppConfig.ADD_QUESTION,
        body: {
          'id': id,
          'exam_id': examId,
          'question_text': text,
          'question_type': type,
          'options': options,
          'correct_answer': correctAnswer,
        },
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }
}
