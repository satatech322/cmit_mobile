// lib/features/recommendation/services/add_recommendation_service.dart

import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/core/global_refresh_event.dart';

class AddRecommendationService {
  /// Add Recommendation to an Inquiry
  static Future<Map<String, dynamic>> addRecommendation({
    required int inquiryId,
    required String recommendation,
    required String penaltyImposed,
  }) async {
    try {
      print("Adding recommendation for Inquiry ID: $inquiryId");

      final Map<String, dynamic> requestBody = {
        "inquiry_id": inquiryId,
        "recommendation": recommendation,
        "penalty_imposed": penaltyImposed,
      };

      print("Request Payload: ${requestBody}");

      final response = await ApiService.post(
        API.addRecommendationInquiry,
        requestBody,
        withAuth: true,
      );

      print("API AddRecommendation Response: ${response.toString()}");

      // Check success and extract data (handles your nested API structure)
      if (response['success'] == true && response.containsKey('data')) {
        final nestedData = response['data'] as Map<String, dynamic>;

        if (nestedData['success'] == true) {
          GlobalRefreshEvent.instance.notify();
          return {
            'success': true,
            'message': nestedData['message'] ?? "Recommendation added successfully",
            'data': nestedData['data'], // optional: in case backend returns created record
          };
        }

        // Backend returned success: false inside data
        return {
          'success': false,
          'message': nestedData['message'] ?? "Failed to add recommendation."
        };
      }

      // Top-level API failure
      return {
        'success': false,
        'message': response['message'] ?? "Failed to add recommendation."
      };
    } catch (e, stackTrace) {
      print("AddRecommendationService: addRecommendation Error - $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': "A network error occurred. Please try again."
      };
    }
  }
}