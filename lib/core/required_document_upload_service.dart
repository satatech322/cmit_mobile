// lib/services/required_document_upload_service.dart

import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/core/global_refresh_event.dart';

class RequiredDocumentUploadService {
  static Future<Map<String, dynamic>> uploadDocument({
    required int requiredDocumentId,
    required String base64WithDataUri, // e.g. "data:application/pdf;base64,..."
  }) async {
    try {
      final payload = {
        "required_document_id": requiredDocumentId,
        "attachment": base64WithDataUri, // send full data URI
      };

      print("Uploading to: ${API.uploadRequiredDocuments}");
      print("Payload: $payload");

      final response = await ApiService.post(
        API.uploadRequiredDocuments,
        payload,
        withAuth: true,
      );

      if (response['success'] == true) {
        // Notify app to reload data
        GlobalRefreshEvent.instance.notify();

        return {
          'success': true,
          'message': response['data']['message'] ?? 'Document uploaded successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Upload failed',
        };
      }
    } catch (e, s) {
      print("Upload Error: $e\n$s");
      return {
        'success': false,
        'message': 'Upload failed. Please try again.',
      };
    }
  }
}