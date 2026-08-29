import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized Logger for API Requests, Responses, and Errors.
/// Formats HTTP network activity with clear visual framing, timestamps,
/// pretty-printed JSON, execution timings, and sanitized base64/sensitive fields.
class ApiLogger {
  static const bool _enabled = true; // Set to false to disable in release if desired

  // Sensitive keys to mask in request payloads
  static const _sensitiveKeys = {
    'password',
    'pass',
    'token',
    'auth_token',
    'access_token',
    'secret',
    'credit_card',
    'authorization',
  };

  /// Main Dio Interceptor to attach to Dio instances
  static Interceptor get interceptor => _ApiDioInterceptor();

  /// Log an outgoing request
  static void logRequest(RequestOptions options) {
    if (!_enabled) return;

    try {
      final buffer = StringBuffer();
      final method = options.method.toUpperCase();
      final uri = options.uri.toString();

      buffer.writeln('┌────────────────────────── 📤 [API REQUEST] ──────────────────────────');
      buffer.writeln('│ 🌐 Method : $method');
      buffer.writeln('│ 🔗 URL    : $uri');

      // Headers (filtered)
      if (options.headers.isNotEmpty) {
        final sanitizedHeaders = _sanitizeMap(options.headers);
        buffer.writeln('│ 📋 Headers: ${_formatJson(sanitizedHeaders, compact: true)}');
      }

      // Query Params
      if (options.queryParameters.isNotEmpty) {
        buffer.writeln('│ 🔍 Params : ${_formatJson(options.queryParameters, compact: true)}');
      }

      // Body / Data
      if (options.data != null) {
        if (options.data is FormData) {
          final formData = options.data as FormData;
          final fields = {for (var e in formData.fields) e.key: _sanitizeValue(e.key, e.value)};
          final files = formData.files.map((e) => '${e.key}: ${e.value.filename ?? "file"} (${e.value.length} B)').join(', ');
          buffer.writeln('│ 📦 Form Data:');
          buffer.writeln('│    Fields: $fields');
          if (files.isNotEmpty) buffer.writeln('│    Files: $files');
        } else {
          buffer.writeln('│ 📦 Payload:');
          final formattedBody = _formatData(options.data);
          for (final line in formattedBody.split('\n')) {
            buffer.writeln('│   $line');
          }
        }
      }

      buffer.writeln('└───────────────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    } catch (e) {
      debugPrint('❌ [ApiLogger Error in logRequest]: $e');
    }
  }

  /// Log a successful or valid response
  static void logResponse(Response response, {int? durationMs}) {
    if (!_enabled) return;

    try {
      final buffer = StringBuffer();
      final statusCode = response.statusCode ?? 0;
      final method = response.requestOptions.method.toUpperCase();
      final uri = response.requestOptions.uri.toString();
      final statusBadge = _getStatusBadge(statusCode);
      final timingStr = durationMs != null ? ' (⏱️ ${durationMs}ms)' : '';

      buffer.writeln('┌────────────────────────── 📥 [API RESPONSE] ──────────────────────────');
      buffer.writeln('│ $statusBadge $timingStr');
      buffer.writeln('│ 🌐 Method : $method');
      buffer.writeln('│ 🔗 URL    : $uri');

      // Response Body
      if (response.data != null) {
        buffer.writeln('│ 📦 Response Data:');
        final formattedBody = _formatData(response.data);
        for (final line in formattedBody.split('\n')) {
          buffer.writeln('│   $line');
        }
      } else {
        buffer.writeln('│ 📦 Response Data: <empty>');
      }

      buffer.writeln('└───────────────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    } catch (e) {
      debugPrint('❌ [ApiLogger Error in logResponse]: $e');
    }
  }

  /// Log an error or failed response
  static void logError(DioException err, {int? durationMs}) {
    if (!_enabled) return;

    try {
      final buffer = StringBuffer();
      final statusCode = err.response?.statusCode;
      final method = err.requestOptions.method.toUpperCase();
      final uri = err.requestOptions.uri.toString();
      final timingStr = durationMs != null ? ' (⏱️ ${durationMs}ms)' : '';
      final statusBadge = statusCode != null ? _getStatusBadge(statusCode) : '🚨 [NETWORK / TIMEOUT ERROR]';

      buffer.writeln('┌────────────────────────── ❌ [API ERROR] ───────────────────────────');
      buffer.writeln('│ $statusBadge $timingStr');
      buffer.writeln('│ 🌐 Method  : $method');
      buffer.writeln('│ 🔗 URL     : $uri');
      buffer.writeln('│ ⚠️ Type    : ${err.type}');
      if (err.message != null && err.message!.isNotEmpty) {
        buffer.writeln('│ 💬 Message : ${err.message}');
      }

      // Error Response Body from server (if available)
      if (err.response?.data != null) {
        buffer.writeln('│ 📦 Error Response:');
        final formattedBody = _formatData(err.response!.data);
        for (final line in formattedBody.split('\n')) {
          buffer.writeln('│   $line');
        }
      }

      buffer.writeln('└───────────────────────────────────────────────────────────────────────');
      debugPrint(buffer.toString());
    } catch (e) {
      debugPrint('❌ [ApiLogger Error in logError]: $e');
    }
  }

  /// Log generic custom message
  static void logInfo(String message, {String? tag}) {
    if (!_enabled) return;
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('ℹ️ [API Info] $prefix$message');
  }

  // --- Helpers ---

  static String _getStatusBadge(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return '✅ [$statusCode OK]';
    } else if (statusCode >= 300 && statusCode < 400) {
      return '🔀 [$statusCode Redirect]';
    } else if (statusCode == 400) {
      return '⚠️ [$statusCode Bad Request]';
    } else if (statusCode == 401) {
      return '🔒 [$statusCode Unauthorized]';
    } else if (statusCode == 403) {
      return '🚫 [$statusCode Forbidden]';
    } else if (statusCode == 404) {
      return '🔍 [$statusCode Not Found]';
    } else if (statusCode == 422) {
      return '📝 [$statusCode Unprocessable Entity / Validation Error]';
    } else if (statusCode >= 400 && statusCode < 500) {
      return '⚠️ [$statusCode Client Error]';
    } else if (statusCode >= 500) {
      return '💥 [$statusCode Internal Server Error]';
    }
    return '🔹 [$statusCode]';
  }

  static String _formatData(dynamic data) {
    if (data == null) return '<null>';
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return _formatJson(_sanitizeDynamic(decoded));
      } catch (_) {
        return _sanitizeString(data);
      }
    } else if (data is Map || data is List) {
      return _formatJson(_sanitizeDynamic(data));
    }
    return data.toString();
  }

  static String _formatJson(dynamic object, {bool compact = false}) {
    try {
      if (compact) {
        return jsonEncode(object);
      }
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(object);
    } catch (_) {
      return object.toString();
    }
  }

  static dynamic _sanitizeDynamic(dynamic value, [String key = '']) {
    if (value is Map) {
      return _sanitizeMap(value);
    } else if (value is List) {
      return value.map((e) => _sanitizeDynamic(e, key)).toList();
    } else if (value is String) {
      return _sanitizeValue(key, value);
    }
    return value;
  }

  static Map<String, dynamic> _sanitizeMap(Map map) {
    final sanitized = <String, dynamic>{};
    for (var entry in map.entries) {
      final key = entry.key.toString();
      sanitized[key] = _sanitizeDynamic(entry.value, key);
    }
    return sanitized;
  }

  static dynamic _sanitizeValue(String key, dynamic value) {
    if (value == null) return null;
    final lowerKey = key.toLowerCase();

    // Check sensitive keys
    for (final sensitive in _sensitiveKeys) {
      if (lowerKey.contains(sensitive)) {
        return '••••••••';
      }
    }

    if (value is String) {
      return _sanitizeString(value);
    }
    return value;
  }

  static String _sanitizeString(String str) {
    // Detect and collapse huge Base64 strings / data URIs
    if (str.startsWith('data:image/') || str.startsWith('data:application/')) {
      final prefix = str.split(';base64,').first;
      return '$prefix;base64,[...${str.length} chars...]';
    }
    if (str.length > 500 && (str.contains('base64') || _looksLikeBase64(str))) {
      return '[Base64 String: ${str.length} characters]';
    }
    return str;
  }

  static bool _looksLikeBase64(String str) {
    if (str.length < 200) return false;
    final sample = str.substring(0, 100);
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sample);
  }
}

/// Internal Dio Interceptor using Stopwatch to calculate precise request duration
class _ApiDioInterceptor extends Interceptor {
  final Map<RequestOptions, Stopwatch> _stopwatches = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _stopwatches[options] = Stopwatch()..start();
    ApiLogger.logRequest(options);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(response.requestOptions);
    stopwatch?.stop();
    final duration = stopwatch?.elapsedMilliseconds;
    ApiLogger.logResponse(response, durationMs: duration);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(err.requestOptions);
    stopwatch?.stop();
    final duration = stopwatch?.elapsedMilliseconds;
    ApiLogger.logError(err, durationMs: duration);
    super.onError(err, handler);
  }
}
