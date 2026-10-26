import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'app_exception.dart';
import 'session_repository.dart';

/// Technical network wiring: one Dio instance shared by every feature.
///
/// Mirrors the admin app's OkHttp setup: attaches a bearer token to
/// non-auth routes, clears the session on 401, and normalizes every failure
/// into an [AppException] with a `{ code, message }` payload.
class ApiClient {
  ApiClient(this._session) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _normalize(ApiConfig.baseUrl),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 40),
        headers: {'Content-Type': 'application/json'},
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final isAuthRoute = options.path.contains('/authentication/');
            final token = _session.accessToken;
            if (!isAuthRoute && token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) {
            // Mirror the web interceptor: an expired session is cleared.
            final isAuthRoute =
                error.requestOptions.path.contains('/authentication/');
            if (error.response?.statusCode == 401 && !isAuthRoute) {
              _session.clear();
            }
            handler.next(error);
          },
        ),
      );
  }

  final SessionRepository _session;
  late final Dio _dio;

  Dio get dio => _dio;

  static String _normalize(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    return '$trimmed/';
  }

  /// Multi-tenant scope helper: merges `ownerAdminId` (when a session is
  /// active) with context-specific query params, mirroring `withOwnerParams`.
  Map<String, String> ownerParams([Map<String, String> extra = const {}]) {
    final owner = _session.activeDataOwnerId;
    if (owner == null || owner.trim().isEmpty) return Map.of(extra);
    return {...extra, 'ownerAdminId': owner};
  }
}

/// Wraps every remote call so repositories only ever throw [AppException].
Future<T> apiCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on DioException catch (e) {
    throw _toAppException(e);
  } on AppException {
    rethrow;
  } catch (e) {
    throw AppException.unexpected(e);
  }
}

AppException _toAppException(DioException e) {
  final status = e.response?.statusCode;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return AppException('TIMEOUT', '');
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return AppException.network();
    default:
      break;
  }
  final response = e.response;
  if (response == null) return AppException.network();
  if (status == 401) return AppException('SESSION_EXPIRED', '', status: 401);
  final data = response.data;
  final raw = data is String ? data : _encode(data);
  return AppException.fromPayload(raw, status: status);
}

String _encode(dynamic data) {
  if (data == null) return '';
  try {
    return jsonEncode(data);
  } catch (_) {
    return data.toString();
  }
}

/// Provided once in `main()` with the preloaded [SessionRepository].
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(sessionRepositoryProvider)),
);
