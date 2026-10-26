import 'dart:convert';

import 'i18n.dart';

/// Unified error model for every bounded context.
///
/// The backend reports failures as `{ code, message }`; the data layer maps
/// transport/HTTP failures into this type so the UI only branches on [code].
class AppException implements Exception {
  AppException(this.code, this.message, {this.status, this.payload});

  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic>? payload;

  /// Human readable message in the current app language.
  ///
  /// Known codes resolve from the i18n catalog (`err.<code>`); unknown codes
  /// fall back to the raw message (usually provided by the backend).
  String userMessage() {
    final localized = AppTexts.translateOrNull('err.$code');
    if (localized != null) return localized;
    if (message.trim().isNotEmpty) return message;
    return AppTexts.translate('err.generic');
  }

  static AppException network() => AppException('NETWORK_ERROR', '');

  static AppException unexpected(Object e) =>
      AppException('UNEXPECTED_ERROR', e.toString());

  /// Builds an [AppException] from a `{ code, message }` JSON error payload.
  static AppException fromPayload(String raw, {int? status}) {
    final parsed = tryParseJson(raw);
    final code = parsed?['code']?.toString();
    final message = parsed?['message']?.toString() ?? '';
    if (code == null || code.isEmpty) {
      return AppException('HTTP_${status ?? 0}', message, status: status);
    }
    return AppException(code, message, status: status, payload: parsed);
  }
}

/// Parses [raw] as a JSON object, returning null when it is not valid JSON.
Map<String, dynamic>? tryParseJson(String raw) {
  if (raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // Not JSON — treat as a plain message upstream.
  }
  return null;
}
