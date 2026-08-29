import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';
import 'local_storage.dart';
import 'api_logger.dart';

class ApiService {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseApiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30), // longer for uploads
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.add(ApiLogger.interceptor);
    return dio;
  }

  /// Public accessor for Dio instance (optional, if other services need it)
  static Dio get dio => _dio;

  /// ✅ Attach Authorization Token
  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    String? token = await LocalStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (withAuth && token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Public version of headers (useful for custom requests)
  static Future<Map<String, String>> getAuthHeaders({bool withAuth = true}) async {
    return await _getHeaders(withAuth: withAuth);
  }

  /// ✅ POST Request (JSON)
  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> data, {
        bool withAuth = true,
      }) async {
    try {
      Response response = await _dio.post(
        endpoint,
        data: jsonEncode(data),
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      ApiLogger.logInfo("Unexpected Error: $e", tag: "POST Exception");
      return {'success': false, 'message': "An unexpected error occurred."};
    }
  }

  /// ✅ GET Request
  static Future<Map<String, dynamic>> get(
      String endpoint, {
        bool withAuth = true,
      }) async {
    try {
      Response response = await _dio.get(
        endpoint,
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      ApiLogger.logInfo("Unexpected Error: $e", tag: "GET Exception");
      return {'success': false, 'message': "An unexpected error occurred."};
    }
  }

  /// ✅ Multipart POST Request (File Uploads)
  static Future<Map<String, dynamic>> postMultipart(
      String endpoint,
      FormData formData, {
        bool withAuth = true,
        ProgressCallback? onSendProgress,
      }) async {
    try {
      Response response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
        onSendProgress: onSendProgress,
      );

      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      ApiLogger.logInfo("Unexpected Upload Error: $e", tag: "Upload Exception");
      return {'success': false, 'message': "An unexpected error occurred during upload."};
    }
  }

  /// Centralized helper to extract error or informative message from API responses
  static String extractErrorMessage(dynamic data, {String defaultMessage = "Something went wrong. Please try again."}) {
    if (data == null) return defaultMessage;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isNotEmpty ? trimmed : defaultMessage;
    }
    if (data is Map) {
      // 1. Common message keys (case variations)
      for (final key in [
        'Response_Message',
        'response_message',
        'Response_message',
        'responseMessage',
        'message',
        'Message',
        'detail',
        'details',
        'msg',
        'error_description'
      ]) {
        if (data[key] != null && data[key].toString().trim().isNotEmpty) {
          return data[key].toString().trim();
        }
      }

      // 2. Descriptive status strings (e.g. "Invalid Username or Password")
      if (data['status'] is String) {
        final statusStr = (data['status'] as String).trim();
        final lower = statusStr.toLowerCase();
        if (statusStr.isNotEmpty &&
            lower != 'error' &&
            lower != 'failed' &&
            lower != 'failure' &&
            lower != 'false' &&
            lower != '0' &&
            lower != 'success' &&
            lower != 'true' &&
            lower != 'ok') {
          return statusStr;
        }
      }

      // 3. Error field
      if (data['error'] != null) {
        if (data['error'] is String && (data['error'] as String).trim().isNotEmpty) {
          return (data['error'] as String).trim();
        } else if (data['error'] is Map) {
          return extractErrorMessage(data['error'], defaultMessage: defaultMessage);
        }
      }

      // 4. Nested validation errors (e.g. Laravel {"errors": {"email": ["..."]}})
      if (data['errors'] != null) {
        if (data['errors'] is Map) {
          final errorsMap = data['errors'] as Map;
          for (var value in errorsMap.values) {
            if (value is List && value.isNotEmpty) {
              final first = value.first.toString().trim();
              if (first.isNotEmpty) return first;
            } else if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          final first = (data['errors'] as List).first.toString().trim();
          if (first.isNotEmpty) return first;
        } else if (data['errors'] is String && (data['errors'] as String).trim().isNotEmpty) {
          return (data['errors'] as String).trim();
        }
      }
    }
    return defaultMessage;
  }

  /// Centralized Dio error handling
  static Map<String, dynamic> _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response?.data;
      final message = extractErrorMessage(
        data,
        defaultMessage: "Server returned an error (${e.response?.statusCode}). Please try again.",
      );
      return {
        'success': false,
        'message': message,
        'status': e.response?.statusCode,
        'data': data,
      };
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return {'success': false, 'message': "Connection timeout. Please try again."};
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': "Server took too long to respond."};
    } else {
      return {'success': false, 'message': "Network issue: Please check your internet connection."};
    }
  }
}