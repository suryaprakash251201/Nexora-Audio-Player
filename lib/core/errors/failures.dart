import 'exceptions.dart';

/// User-facing failures mapped from exceptions.
/// UI shows `message`, logs `code`.
class Failure {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure(this.message, {this.code, this.statusCode});

  factory Failure.fromException(Object e) {
    final raw = e.toString();
    // iOS Keychain errSecDuplicateItem (-25299) or other secure-storage issues
    if (raw.contains('-25299') ||
        raw.toLowerCase().contains('keychain') ||
        raw.toLowerCase().contains('security result')) {
      return const Failure(
        'Could not save credentials on this device (keychain error). Tap "Clear stored session" below and try again.',
        code: 'KEYCHAIN_ERROR',
      );
    }
    if (e is ApiException) {
      return Failure(_userMessage(e), code: e.code, statusCode: e.statusCode);
    }
    // Unwrap stringified exceptions like "Exception: message"
    if (raw.startsWith('Exception: ')) {
      return Failure(raw.substring(11));
    }
    return Failure(raw);
  }

  static String _userMessage(ApiException e) {
    // For auth/validation, always show server message directly
    final code = e.code?.toLowerCase() ?? '';
    if (code.contains('invalid_credentials') ||
        code.contains('validation') ||
        code.contains('csrf') ||
        code.contains('forbidden') ||
        code.contains('invalid') ||
        code.contains('account_locked') ||
        code.contains('too_many')) {
      return e.message;
    }
    switch (e.code) {
      case 'NO_INTERNET':
        return 'No internet connection. Check Wi-Fi and that 192.168.1.5 is reachable on same network. Showing cached content where available.';
      case 'TIMEOUT':
        return 'Server is taking too long to respond (15s). Check that 192.168.1.5 is on and not blocked by firewall.';
      case 'UNAUTHORIZED':
        return e.message.isNotEmpty && e.message != 'Unauthorized'
            ? e.message
            : 'Invalid username or password. Try admin / amma@123.';
      case 'NOT_FOUND':
        return 'Endpoint not found (404). Server URL may be wrong - try http://192.168.1.5';
      case 'SERVER_ERROR':
        return 'Server error (${e.statusCode}). Please try again later.';
      case 'BAD_SERVER_URL':
        return 'Invalid server URL. For LAN use: http://192.168.1.5';
      case 'VALIDATION_ERROR':
        return e.message;
      default:
        if (e.statusCode == 403)
          return e.message.isNotEmpty
              ? e.message
              : 'Access forbidden. Check CSRF or permissions.';
        if (e.statusCode == 429)
          return 'Too many attempts - account briefly locked. Wait 1-2 minutes.';
        if (e.statusCode != null && e.statusCode! >= 500)
          return 'Server unavailable (${e.statusCode}). Try again later.';
        return e.message.isEmpty ? 'Something went wrong.' : e.message;
    }
  }

  @override
  String toString() => 'Failure($code): $message';
}
