import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/inquiries/model/visit_inquiry_model.dart';
import 'package:cmit/core/global_refresh_event.dart';

class VisitInquiryService {
  /// Save Visit for an Inquiry
  static Future<Map<String, dynamic>> addVisit({
    required String visitDate,
    required String visitTime,
    required int vehicleId,
    required int driverId,
    required int inquiryId,
  }) async {
    try {
      final visitData = VisitInquiryModel(
        visitDate: visitDate,
        visitTime: visitTime,
        vehicleId: vehicleId,
        driverId: driverId,
        inquiryId: inquiryId,
      );

      print("Adding Visit → ${API.addVisitInquiry}");
      print("Payload: ${visitData.toJson()}");

      final response = await ApiService.post(
        API.addVisitInquiry,
        visitData.toJson(),
        withAuth: true,
      );

      print("Add Visit API Response: $response");

      if (response['success'] == true && response.containsKey('data')) {
        final apiData = response['data'] as Map<String, dynamic>;

        if (apiData['success'] == true) {
          GlobalRefreshEvent.instance.notify();
          return {
            'success': true,
            'message': apiData['message'] ?? "Visit scheduled successfully!",
            'data': apiData['data'] != null
                ? VisitInquiryModel.fromJson(apiData['data'])
                : null,
          };
        }

        return {
          'success': false,
          'message': apiData['message'] ?? "Failed to schedule visit.",
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? "Something went wrong. Please try again.",
      };
    } catch (e, stackTrace) {
      print("VisitInquiryService Error: $e\n$stackTrace");
      return {
        'success': false,
        'message': "Network error. Please check your connection and try again.",
      };
    }
  }
}