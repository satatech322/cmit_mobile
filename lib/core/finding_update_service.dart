import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';

class FindingInquiryService {
  /// Update existing finding with rich text (Delta JSON) and base64 images
  static Future<Map<String, dynamic>> updateFindingInquiry({
    required int findingId,
    required String findings, // Delta JSON as string
    required List<String> files, // List of data:image/...;base64,... strings
  }) async {
    try {
      final data = {
        "finding_id": findingId,
        "findings": findings,
        "files": files,
      };

      print("Updating finding ID: $findingId");
      print("Payload: $data");

      final response = await ApiService.post(
        API.updateFindingInquiry,
        data,
        withAuth: true,
      );

      if (response['success'] == true) {
        return {
          'success': true,
          'message': response['data']['message'] ?? 'Finding updated successfully',
          'data': response['data'],
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update finding',
        };
      }
    } catch (e, stackTrace) {
      print("updateFindingInquiry Error: $e\n$stackTrace");
      return {
        'success': false,
        'message': 'Network error. Please check your connection and try again.',
      };
    }
  }
}