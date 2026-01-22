import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/inquiries/model/finalized_finding_model.dart'; // adjust path as needed

class FinalizedFindingService {
  /// Store Finalized Finding (POST /api/v1/store/finding/finalized/inquiries)
  static Future<Map<String, dynamic>> storeFinalizedFinding({
    required String combinedFindings,
    required int visitId,
    required int inquiryId,
  }) async {
    try {
      final payload = {
        'combined_findings': combinedFindings.trim(),
        'visit_id': visitId,
        'inquiry_id': inquiryId,
      };

      print("📤 Sending finalized finding to: ${API.storeFinalizedFindingInquiry}");
      print("📦 Payload: $payload}");

      final response = await ApiService.post(
        API.storeFinalizedFindingInquiry, // Now using the correct dedicated endpoint
        payload,
        withAuth: true,
      );

      print("✅ Finalized finding response: $response");

      if (response['success'] == true) {
        // Optional: parse returned data if API sends back the saved object
        if (response['data'] is Map<String, dynamic>) {
          final model = FinalizedFindingModel.fromJson(response['data']);
          return {
            'success': true,
            'message': 'Finalized finding saved successfully',
            'data': model,
          };
        }

        return {
          'success': true,
          'message': 'Finalized finding saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to save finalized finding',
        };
      }
    } catch (e, stackTrace) {
      print("❌ FinalizedFindingService Error: $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': 'Network error. Please try again.',
      };
    }
  }
}