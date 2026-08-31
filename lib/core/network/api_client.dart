import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../errors/exceptions.dart';
import '../logging/app_logger.dart';
import '../storage/secure_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage);
});

class ApiClient {
  final SecureStorageService _secureStorage;
  late final Dio _dio;

  // Refresh lock
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        responseType: ResponseType.json,
        validateStatus: (s) =>
            s != null && s < 500, // let 4xx be handled manually
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ensure baseUrl is set per-request (user may change server)
          if (options.baseUrl.isEmpty ||
              options.baseUrl == 'http://localhost:3000/api/v1') {
            final serverUrl = await _secureStorage.getServerUrl();
            if (serverUrl != null && serverUrl.isNotEmpty) {
              options.baseUrl = serverUrl;
            } else if (AppConfig.envBaseUrl.isNotEmpty) {
              options.baseUrl = AppConfig.normalizeUrl(AppConfig.envBaseUrl);
            }
          }

          // Attach token
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          options.headers['X-Platform'] = Platform.isAndroid
              ? 'android'
              : Platform.isIOS
              ? 'ios'
              : 'other';

          if (kDebugMode) {
            AppLogger.api(
              '${options.method} ${options.baseUrl}${options.path} ${options.queryParameters.isEmpty ? '' : options.queryParameters}',
            );
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            AppLogger.api(
              '← ${response.statusCode} ${response.requestOptions.path}',
            );
          }
          // Map 401..499 to exception handling in call-site, but we still intercept 401 for auto-logout/refresh
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final status = error.response?.statusCode;
          final req = error.requestOptions;

          if (kDebugMode) {
            AppLogger.api(
              '✗ ${error.type} ${status ?? ''} ${req.path} ${AppLogger.redact(error.message ?? '')}',
            );
          }

          // No internet / timeout
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            return handler.reject(
              DioException(
                requestOptions: req,
                error: const TimeoutException(),
                type: DioExceptionType.connectionTimeout,
              ),
            );
          }
          if (error.type == DioExceptionType.connectionError ||
              (error.error is SocketException)) {
            return handler.reject(
              DioException(
                requestOptions: req,
                error: const NoInternetException(),
                type: DioExceptionType.connectionError,
              ),
            );
          }

          if (status == 401) {
            // Avoid infinite loop for auth endpoints
            final path = req.path;
            if (path.contains('/auth/login') ||
                path.contains('/auth/refresh')) {
              await _secureStorage.deleteToken();
              return handler.next(error);
            }

            // Try refresh once
            final refreshed = await _attemptRefresh();
            if (refreshed) {
              try {
                final token = await _secureStorage.getToken();
                if (token != null) {
                  req.headers['Authorization'] = 'Bearer $token';
                }
                final retry = await _dio.fetch(req);
                return handler.resolve(retry);
              } catch (e) {
                // retry failed, fall through
              }
            } else {
              await _secureStorage.deleteToken();
            }
          }

          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => AppLogger.api(o.toString()),
        ),
      );
    }
  }

  Dio get dio => _dio;
  Dio get client => _dio;

  Future<bool> _attemptRefresh() async {
    if (_isRefreshing) {
      try {
        await _refreshCompleter?.future.timeout(const Duration(seconds: 10));
        final token = await _secureStorage.getToken();
        return token != null && token.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    _isRefreshing = true;
    _refreshCompleter = Completer<void>();
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      final serverUrl = await _secureStorage.getServerUrl();
      if (refreshToken == null || refreshToken.isEmpty || serverUrl == null) {
        _refreshCompleter?.complete();
        return false;
      }
      // Direct Dio without interceptor loop
      final refreshDio = Dio(BaseOptions(baseUrl: serverUrl));
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300) {
        final data = res.data is Map ? res.data as Map : {};
        // Support both {accessToken} and {data: {accessToken}}
        final payload = data['data'] is Map ? data['data'] as Map : data;
        final newToken =
            payload['accessToken'] ??
            payload['token'] ??
            payload['access_token'];
        final newRefresh = payload['refreshToken'] ?? payload['refresh_token'];
        if (newToken is String && newToken.isNotEmpty) {
          await _secureStorage.saveToken(newToken);
          if (newRefresh is String && newRefresh.isNotEmpty) {
            await _secureStorage.saveRefreshToken(newRefresh);
          }
          AppLogger.auth('Token refreshed');
          _refreshCompleter?.complete();
          return true;
        }
      }
      _refreshCompleter?.complete();
      return false;
    } catch (e) {
      if (!(_refreshCompleter?.isCompleted ?? true))
        _refreshCompleter?.complete();
      AppLogger.auth('Refresh failed: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Helpers to unwrap envelopes and map errors

  /// Throws [ApiException] on non-2xx.
  void _throwIfError(Response res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    final data = res.data;
    String message = 'Request failed ($status)';
    String? code;
    dynamic details;
    if (data is Map) {
      // Nexora style: {"error":"code_string","message":"human"}
      if (data['error'] is String) {
        code = data['error']?.toString();
        if (data['message'] is String) {
          message = data['message'] as String;
        } else {
          message = code ?? message;
        }
        details = data['details'] ?? data['request'];
      } else if (data['error'] is Map) {
        final err = data['error'] as Map;
        message = (err['message'] ?? err['msg'] ?? message).toString();
        code = err['code']?.toString() ?? err['error']?.toString();
        details = err['details'];
      } else if (data['message'] is String) {
        message = data['message'] as String;
        if (data['error'] is String) code = data['error'] as String;
      } else if (data['msg'] is String) {
        message = data['msg'] as String;
      }
      // Fallback code from string error
      code ??= data['code']?.toString();
    }
    if (status == 401) throw UnauthorizedException(message);
    if (status == 403) {
      // CSRF or forbidden - surface as 403 with code
      throw ApiException(
        message,
        statusCode: 403,
        code: code ?? 'FORBIDDEN',
        details: details,
      );
    }
    if (status == 404) throw NotFoundException(message);
    if (status == 409)
      throw ApiException(message, statusCode: 409, code: code ?? 'CONFLICT');
    if (status == 422) throw ValidationException(message, details: details);
    if (status == 429)
      throw ApiException(message, statusCode: 429, code: 'RATE_LIMITED');
    if (status >= 500) throw ServerException(message, statusCode: status);
    throw ApiException(
      message,
      statusCode: status,
      code: code,
      details: details,
    );
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    // Handles {success:true, data:{...}} or {data: [...]}
    if (json.containsKey('data')) {
      final inner = json['data'];
      if (inner is Map<String, dynamic>) return inner;
      // If data is list, return original (caller will handle)
    }
    return json;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
      _throwIfError(res);
      return res;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
      _throwIfError(res);
      return res;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      final res = await _dio.put(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
      _throwIfError(res);
      return res;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.delete(path, data: data, queryParameters: query);
      _throwIfError(res);
      return res;
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  ApiException _mapDio(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String msg = e.message ?? 'Network error';
    String? code;
    if (data is Map) {
      if (data['error'] is String) {
        code = data['error']?.toString();
        if (data['message'] is String) msg = data['message'] as String;
      } else if (data['error'] is Map) {
        final err = data['error'] as Map;
        msg = (err['message'] ?? msg).toString();
        code = err['code']?.toString();
      } else if (data['message'] is String) {
        msg = data['message'] as String;
        if (data['error'] is String) code = data['error'] as String;
      }
      // Also capture bare 'msg'
      if (msg == 'Network error' && data['msg'] is String) {
        msg = data['msg'] as String;
      }
    }
    // Include HTTP status in message if still generic
    if (msg == 'Network error' && status != null) {
      msg = 'Request failed ($status)';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const TimeoutException();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return const NoInternetException();
    }
    if (status == 401) return UnauthorizedException(msg);
    if (status == 403)
      return ApiException(msg, statusCode: 403, code: code ?? 'FORBIDDEN');
    if (status == 404) return NotFoundException(msg);
    if (status == 422) return ValidationException(msg);
    if (status != null && status >= 500)
      return ServerException(msg, statusCode: status);
    return ApiException(msg, statusCode: status, code: code);
  }

  // Convenience for health check (no auth needed) — uses origin.
  Future<bool> testConnection(String rawUrl) async {
    final normalized = AppConfig.normalizeUrl(rawUrl);
    final origin = normalized.split('/api').first;
    final probe = Dio(
      BaseOptions(
        baseUrl: origin,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    try {
      // Nexora real endpoints: /healthz, /health, /api/v1/version, /api/v1/auth/needs-setup
      for (final p in [
        '/healthz',
        '/health',
        '/api/v1/version',
        '/api/v1/auth/needs-setup',
        '/api/v1/auth/session',
        '/api/v1/server/info',
        '/api/v1/health',
        '/',
      ]) {
        try {
          final r = await probe.get(p);
          if (r.statusCode != null &&
              r.statusCode! < 500 &&
              r.statusCode != 404) {
            // Even 401 means server is reachable and API exists
            return true;
          }
          // 404 still means reachable (server responded)
          if (r.statusCode == 404 && p == '/') {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      // If all probes fail, try direct TCP connect via Dio error type check
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> probeServer(String rawUrl) async {
    final normalized = AppConfig.normalizeUrl(rawUrl);
    final origin = normalized.split('/api').first;
    final probe = Dio(
      BaseOptions(
        baseUrl: origin,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        validateStatus: (s) => true,
      ),
    );
    final results = <String, dynamic>{
      'origin': origin,
      'normalized': normalized,
    };
    for (final p in [
      '/healthz',
      '/api/v1/version',
      '/api/v1/auth/needs-setup',
    ]) {
      try {
        final r = await probe.get(p);
        results[p] = {'status': r.statusCode, 'body': r.data};
      } catch (e) {
        results[p] = {'error': e.toString()};
      }
    }
    return results;
  }
}
