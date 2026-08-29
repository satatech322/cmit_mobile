import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/core/global_refresh_event.dart';

class AnnexFileService {
  /// Upload images as data URLs (data:image/jpeg;base64,...)
  /// - payload: Map containing 'annex_id' and 'files' array of data URLs
  static Future<Map<String, dynamic>> uploadAnnexImages(
      Map<String, dynamic> payload,
      ) async {
    try {
      print("🚀 Starting annex image upload (data URLs)...");
      print("Annex ID: ${payload['annex_id']}");
      print("Files count: ${(payload['files'] as List).length}");

      final response = await ApiService.post(
        API.uploadAnnexFile,
        payload,
        withAuth: true,
      );

      if (response['success']) {
        GlobalRefreshEvent.instance.notify();
        return {
          'success': true,
          'message': response['data']['message'] ?? 'Images uploaded successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Upload failed',
        };
      }
    } catch (e, stackTrace) {
      print("❌ AnnexFileService Error (data URLs): $e");
      print("StackTrace: $stackTrace");
      return {
        'success': false,
        'message': 'An unexpected error occurred during image upload.',
      };
    }
  }

  /// Upload one or multiple annex files as base64
  /// - files: List<Map<String, dynamic>> containing base64 data
  /// - annexId: int (e.g., 4)
  /// - onProgress: Optional callback (not used in this method, progress tracked during conversion)
  static Future<Map<String, dynamic>> uploadAnnexFileBase64({
    required List<Map<String, dynamic>> files,
    required int annexId,
    ProgressCallback? onProgress,
  }) async {
    try {
      print("🚀 Starting annex file upload (base64)...");
      print("Annex ID: $annexId");
      print("Files count: ${files.length}");

      final data = {
        'annex_id': annexId,
        'files': files.map((file) {
          return {
            'name': file['name'],
            'base64': file['base64'],
            'mime_type': file['mime_type'],
            'size': file['size'],
          };
        }).toList(),
      };

      final response = await ApiService.post(
        API.uploadAnnexFile,
        data,
        withAuth: true,
      );

      if (response['success']) {
        GlobalRefreshEvent.instance.notify();
        return {
          'success': true,
          'message': response['data']['message'] ?? 'Files uploaded successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Upload failed',
        };
      }
    } catch (e, stackTrace) {
      print("❌ AnnexFileService Error (base64): $e");
      print("StackTrace: $stackTrace");
      return {
        'success': false,
        'message': 'An unexpected error occurred during file upload.',
      };
    }
  }

  /// Upload one or multiple annex files (original multipart method - kept as backup)
  /// - files: List<File> (can be single or multiple)
  /// - annexId: int (e.g., 4)
  static Future<Map<String, dynamic>> uploadAnnexFile({
    required List<File> files,
    required int annexId,
    ProgressCallback? onProgress,
  }) async {
    try {
      print("🚀 Starting annex file upload (multipart)...");
      print("Annex ID: $annexId");
      print("Files count: ${files.length}");

      FormData formData = FormData();

      formData.fields.add(MapEntry('annex_id', annexId.toString()));

      for (var file in files) {
        String fileName = file.path.split(Platform.isAndroid || Platform.isIOS ? '/' : RegExp(r'[/\\]')).last;
        formData.files.add(MapEntry(
          'files[]',
          await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          ),
        ));
      }

      final response = await ApiService.postMultipart(
        API.uploadAnnexFile,
        formData,
        withAuth: true,
        onSendProgress: onProgress ?? (sent, total) {
          double progress = (sent / total) * 100;
          print("Upload Progress: ${progress.toStringAsFixed(1)}%");
        },
      );

      if (response['success']) {
        GlobalRefreshEvent.instance.notify();
        return {
          'success': true,
          'message': response['data']['message'] ?? 'Files uploaded successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Upload failed',
        };
      }
    } catch (e, stackTrace) {
      print("❌ AnnexFileService Error (multipart): $e");
      print("StackTrace: $stackTrace");
      return {
        'success': false,
        'message': 'An unexpected error occurred during file upload.',
      };
    }
  }

  /// Helper method to convert file to base64
  static Future<String> fileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print("❌ Error converting file to base64: $e");
      rethrow;
    }
  }
}