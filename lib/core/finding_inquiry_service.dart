// lib/core/finding_inquiry_service.dart
import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/inquiries/model/finding_inquiry_model.dart';
import 'package:cmit/core/global_refresh_event.dart';

class FindingInquiryService {
  /// Save Finding for a Visit with optional file attachments
  static Future<Map<String, dynamic>> storeFinding({
    required String findings,
    required int visitId,
    List<String>? files,
  }) async {
    try {
      final payload = FindingInquiryModel(
        findings: findings,
        visitId: visitId,
        files: files,
      );

      print("Storing Finding → ${API.storeFindingInquiry}");
      print("Payload: ${payload.toJson()}");
      if (files != null) {
        print("Number of files: ${files.length}");
      }

      final response = await ApiService.post(
        API.storeFindingInquiry,
        payload.toJson(),
        withAuth: true,
      );

      print("Store Finding API Response: $response");

      if (response['success'] == true && response.containsKey('data')) {
        final apiData = response['data'] as Map<String, dynamic>;

        if (apiData['success'] == true) {
          // Notify app to reload data
          GlobalRefreshEvent.instance.notify();
          
          return {
            'success': true,
            'message': apiData['message'] ?? "Finding saved successfully!",
            'data': apiData['data'] != null
                ? FindingInquiryModel.fromJson(apiData['data'])
                : null,
          };
        }

        return {
          'success': false,
          'message': apiData['message'] ?? "Failed to save finding.",
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? "Something went wrong. Please try again.",
      };
    } catch (e, stackTrace) {
      print("FindingInquiryService Error: $e\n$stackTrace");
      return {
        'success': false,
        'message': "Network error. Please check your connection and try again.",
      };
    }
  }
}