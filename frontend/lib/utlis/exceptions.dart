class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({required String message, String? code})
      : super(
          message: 'Network Error: $message',
          code: code ?? 'NETWORK_ERROR',
        );
}

class ServerException extends AppException {
  final int statusCode;

  ServerException({
    required String message,
    required this.statusCode,
    String? code,
  }) : super(
          message: 'Server Error ($statusCode): $message',
          code: code ?? 'SERVER_ERROR_$statusCode',
        );
}

class AuthException extends AppException {
  AuthException({required String message, String? code})
      : super(
          message: message,
          code: code ?? 'AUTH_ERROR',
        );
}

class ValidationException extends AppException {
  ValidationException({required String message})
      : super(
          message: message,
          code: 'VALIDATION_ERROR',
        );
}

class DataException extends AppException {
  DataException({required String message})
      : super(
          message: message,
          code: 'DATA_ERROR',
        );
}
