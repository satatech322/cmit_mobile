import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/inquiries/model/required_documents_model.dart';
import 'package:cmit/core/global_refresh_event.dart';

class RequiredDocumentsService {
  /// Store Required Documents for an Inquiry
  static Future<Map<String, dynamic>> storeRequiredDocuments({
    required int inquiryId,
    required int attachmentTypeId,
  }) async {
    try {
      final payload = {
        "inquiry_id": inquiryId,
        "attachment_type_id": attachmentTypeId,
      };

      print("Storing required documents for inquiry: $inquiryId");

      final response = await ApiService.post(
        API.storeRequiredDocuments,
        payload,
        withAuth: true,
      );

      print("Store Required Documents Raw Response: $response");

      if (response['success'] == true) {
        final result = RequiredDocumentsResponse.fromJson(response);
        
        // Notify app to reload data
        GlobalRefreshEvent.instance.notify();

        return {
          'success': true,
          'message': result.message,
          'data': result.data,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to store required documents',
        };
      }
    } catch (e, stackTrace) {
      print("RequiredDocumentsService Error: $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': "Network error. Please try again.",
      };
    }
  }
}