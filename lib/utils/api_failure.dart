import 'package:dio/dio.dart';

abstract class ApiFailure {
  final String message;
  const ApiFailure(this.message);
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure() : super('No internet connection');
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure() : super('Session expired. Please log in again.');
}

class NotFoundFailure extends ApiFailure {
  final String? errorCode;
  const NotFoundFailure(super.message, {this.errorCode});
}

class ConflictFailure extends ApiFailure {
  final String? errorCode;
  const ConflictFailure(super.message, {this.errorCode});
}

class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message);
}

class ServerFailure extends ApiFailure {
  const ServerFailure(super.message);
}

class UnknownFailure extends ApiFailure {
  const UnknownFailure(super.message);
}

ApiFailure mapDioError(DioException err) {
  if (err.type == DioExceptionType.connectionError ||
      err.type == DioExceptionType.unknown) {
    return const NetworkFailure();
  }

  final statusCode = err.response?.statusCode;
  final body = err.response?.data as Map<String, dynamic>?;
  final message = body?['message'] as String? ?? err.message ?? 'Unknown error';
  final errorCode = body?['errorCode'] as String?;

  switch (statusCode) {
    case 400:
      return ValidationFailure(message);
    case 401:
      return const UnauthorizedFailure();
    case 404:
      return NotFoundFailure(message, errorCode: errorCode);
    case 409:
      return ConflictFailure(message, errorCode: errorCode);
    case 500:
      return const ServerFailure('Server error. Please try again.');
    default:
      return UnknownFailure(message);
  }
}
