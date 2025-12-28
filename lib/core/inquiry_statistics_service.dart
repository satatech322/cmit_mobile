import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/home/model/inquiry_statistics_model.dart'; // adjust path as needed

class InquiryStatisticsService {
  /// Fetch Inquiry Statistics
  static Future<Map<String, dynamic>> getInquiryStatistics() async {
    try {
      print("Fetching inquiry statistics from: ${API.getInquiryStatistics}");

      final response = await ApiService.get(
        API.getInquiryStatistics,
        withAuth: true,
      );

      print("API InquiryStatistics Raw Response: $response");

      // Expected response: { success: true, total: 3, pending: 3, completed: 0 }
      if (response['success'] == true && response.containsKey('data')) {
        final rawData = response['data'];

        if (rawData is Map<String, dynamic> &&
            rawData.containsKey('total') &&
            rawData.containsKey('pending') &&
            rawData.containsKey('completed')) {

          final statistics = InquiryStatisticsModel.fromJson(rawData);

          return {
            'success': true,
            'message': "Inquiry statistics fetched successfully",
            'data': statistics,
          };
        }
      }

      // Fallback if structure doesn't match
      return {
        'success': false,
        'message': 'Invalid response format from server',
      };
    } catch (e, stackTrace) {
      print("InquiryStatisticsService Error: $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': "Network error. Please try again.",
      };
    }
  }
}