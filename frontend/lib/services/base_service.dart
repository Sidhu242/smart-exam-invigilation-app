import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../utlis/exceptions.dart';

class BaseService {
  static final BaseService _instance = BaseService._internal();
  final http.Client _httpClient = http.Client();

  factory BaseService() => _instance;

  BaseService._internal();

  /// GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final uri = Uri.parse('${AppConfig.SERVER_URL}$endpoint');
      final response = await _httpClient
          .get(uri, headers: _getHeaders())
          .timeout(AppConfig.CONNECT_TIMEOUT);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.SERVER_URL}$endpoint');
      final response = await _httpClient
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(AppConfig.CONNECT_TIMEOUT);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${AppConfig.SERVER_URL}$endpoint');
      final response = await _httpClient
          .delete(uri, headers: _getHeaders())
          .timeout(AppConfig.CONNECT_TIMEOUT);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw ServerException(
          message: data['message'] ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Handle errors
  AppException _handleError(dynamic e) {
    if (e is AppException) {
      return e;
    } else if (e.toString().contains('Connection') ||
        e.toString().contains('SocketException')) {
      return NetworkException(message: 'Unable to connect to server');
    } else {
      return NetworkException(message: e.toString());
    }
  }

  /// Get headers
  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };
}
