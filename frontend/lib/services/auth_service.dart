import 'base_service.dart';
import '../config/constants.dart';
import '../utlis/exceptions.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final BaseService _baseService = BaseService();

  factory AuthService() => _instance;

  AuthService._internal();

  /// Login user
  Future<Map<String, dynamic>> login(String id, String password) async {
    if (id.isEmpty || password.isEmpty) {
      throw ValidationException(message: 'ID and password required');
    }

    try {
      final response = await _baseService.post(
        AppConfig.LOGIN,
        body: {'id': id, 'password': password},
      );

      if (response['status'] == 'success') {
        return response;
      } else {
        throw AuthException(message: response['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Sign up user
  Future<Map<String, dynamic>> signup({
    required String id,
    required String name,
    required String password,
    required String role,
    required String institution,
  }) async {
    if (id.isEmpty ||
        name.isEmpty ||
        password.isEmpty ||
        role.isEmpty ||
        institution.isEmpty) {
      throw ValidationException(message: AppStrings.MISSING_FIELDS);
    }

    try {
      final response = await _baseService.post(
        AppConfig.SIGNUP,
        body: {
          'id': id,
          'name': name,
          'password': password,
          'role': role,
          'institution': institution,
        },
      );

      if (response['status'] == 'success') {
        return response;
      } else {
        throw AuthException(message: response['message'] ?? 'Signup failed');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(message: e.toString());
    }
  }

  /// Logout
  void logout() {
    // Clear any tokens/cache
  }
}
