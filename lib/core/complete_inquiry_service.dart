import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';

class CompleteInquiryService {
  /// Mark an inquiry as complete
  static Future<Map<String, dynamic>> completeInquiry({
    required int inquiryId,
  }) async {
    try {
      print("🔴🔴🔴 STARTING COMPLETE INQUIRY 🔴🔴🔴");
      print("🔄 Completing inquiry ID: $inquiryId");

      // Build the endpoint
      final endpoint = "${ApiConfig.baseApiUrl}/store/complete/inquiries";
      print("📍 Full Endpoint: $endpoint");

      // Payload exactly as API expects
      final payload = {
        "inquiry_id": inquiryId,
      };
      print("📦 Payload being sent: $payload");

      print("🚀 About to call ApiService.post()...");

      final response = await ApiService.post(
        endpoint,
        payload,
        withAuth: true,
      );

      print("✅ API Response received: $response");

      if (response['success'] == true) {
        print("✅✅✅ SUCCESS! Inquiry completed");
        return {
          'success': true,
          'message': response['data']['message'] ?? 'Inquiry completed successfully',
          'data': response['data'],
        };
      } else {
        print("❌ API returned success=false");
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to complete inquiry',
        };
      }
    } catch (e, stackTrace) {
      print("❌❌❌ EXCEPTION CAUGHT IN SERVICE ❌❌❌");
      print("❌ CompleteInquiryService Error: $e");
      print("📍 StackTrace: $stackTrace");
      return {
        'success': false,
        'message': "Network error: $e",
      };
    }
  }
}