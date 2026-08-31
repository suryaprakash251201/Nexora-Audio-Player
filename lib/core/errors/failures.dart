import 'exceptions.dart';

/// User-facing failures mapped from exceptions.
/// UI shows `message`, logs `code`.
class Failure {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure(this.message, {this.code, this.statusCode});

  factory Failure.fromException(Object e) {
    if (e is ApiException) {
      return Failure(_userMessage(e), code: e.code, statusCode: e.statusCode);
    }
    return Failure(e.toString());
  }

  static String _userMessage(ApiException e) {
    switch (e.code) {
      case 'NO_INTERNET':
        return 'No internet connection. Showing cached content where available.';
      case 'TIMEOUT':
        return 'Server is taking too long to respond. Check your connection.';
      case 'UNAUTHORIZED':
        return 'Session expired. Please log in again.';
      case 'NOT_FOUND':
        return 'Requested content was not found.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'BAD_SERVER_URL':
        return 'Invalid server URL. Please check the address.';
      case 'VALIDATION_ERROR':
        return e.message;
      default:
        if (e.statusCode == 429) return 'Too many requests. Please wait a moment.';
        if (e.statusCode != null && e.statusCode! >= 500) return 'Server unavailable. Try again later.';
        return e.message.isEmpty ? 'Something went wrong.' : e.message;
    }
  }

  @override
  String toString() => 'Failure($code): $message';
}
