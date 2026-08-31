class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final dynamic details;

  const ApiException(this.message, {this.statusCode, this.code, this.details});

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message, {super.statusCode, super.code});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String msg = 'Unauthorized'])
      : super(msg, statusCode: 401, code: 'UNAUTHORIZED');
}

class NotFoundException extends ApiException {
  const NotFoundException([String msg = 'Not found']) : super(msg, statusCode: 404, code: 'NOT_FOUND');
}

class ValidationException extends ApiException {
  const ValidationException(super.message, {super.details}) : super(statusCode: 422, code: 'VALIDATION_ERROR');
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.statusCode}) : super(code: 'SERVER_ERROR');
}

class NoInternetException extends ApiException {
  const NoInternetException() : super('No internet connection', code: 'NO_INTERNET');
}

class TimeoutException extends ApiException {
  const TimeoutException() : super('Connection timed out', code: 'TIMEOUT');
}

class BadServerUrlException extends ApiException {
  const BadServerUrlException([String msg = 'Invalid server URL']) : super(msg, code: 'BAD_SERVER_URL');
}
