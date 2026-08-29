import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api.dart';
import 'local_storage.dart';

class ApiService {
  static final Dio _dio = Dio(
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
      print("📤 Sending POST Request to: $endpoint");
      print("📦 Request Data: ${jsonEncode(data)}");

      Response response = await _dio.post(
        endpoint,
        data: jsonEncode(data),
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
      );

      print("✅ Success! Response: ${response.data}");
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      print("❌ Unexpected Error: $e");
      return {'success': false, 'message': "An unexpected error occurred."};
    }
  }

  /// ✅ GET Request
  static Future<Map<String, dynamic>> get(
      String endpoint, {
        bool withAuth = true,
      }) async {
    try {
      print("📤 Sending GET Request to: $endpoint");

      Response response = await _dio.get(
        endpoint,
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
      );

      print("✅ Success! Response: ${response.data}");
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      print("❌ Unexpected Error: $e");
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
      print("📤 Sending Multipart POST to: $endpoint");

      Response response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: await _getHeaders(withAuth: withAuth)),
        onSendProgress: onSendProgress,
      );

      print("✅ Upload Success: ${response.data}");
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      print("❌ Unexpected Upload Error: $e");
      return {'success': false, 'message': "An unexpected error occurred during upload."};
    }
  }

  /// Centralized Dio error handling
  static Map<String, dynamic> _handleDioError(DioException e) {
    if (e.response != null) {
      print("❌ API Error [${e.response?.statusCode}]: ${e.response?.data}");
      final data = e.response?.data;
      String message;
      if (data is Map) {
        message = data['message']?.toString() ?? "Something went wrong";
      } else {
        message = "Server returned an error (${e.response?.statusCode}). Please try again.";
      }
      return {
        'success': false,
        'message': message,
        'status': e.response?.statusCode,
      };
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return {'success': false, 'message': "Connection timeout. Please try again."};
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return {'success': false, 'message': "Server took too long to respond."};
    } else {
      print("❌ Network Error: ${e.message}");
      return {'success': false, 'message': "Network issue: Please check your internet connection."};
    }
  }
}