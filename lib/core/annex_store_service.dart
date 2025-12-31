// features/inquiries/services/annex_service.dart

import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/inquiries/model/annex_store_model.dart';
import 'package:cmit/core/global_refresh_event.dart';

class AnnexService {
  /// Store a new Annex
  static Future<Map<String, dynamic>> storeAnnex({
    required String title,
    required int inquiryId,
  }) async {
    try {
      final payload = {
        "title": title,
        "inquiry_id": inquiryId,
      };

      print("Storing Annex → Payload: $payload");

      final response = await ApiService.post(
        API.storeAnnex,
        payload,
        withAuth: true,
      );

      if (response['success'] == true) {
        final annex = AnnexModel.fromJson(response['data']);
        
        // Notify app to reload data
        GlobalRefreshEvent.instance.notify();

        return {
          'success': true,
          'message': response['data']['message'] ?? 'Annex added successfully',
          'data': annex,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to add annex',
        };
      }
    } catch (e, stackTrace) {
      print("AnnexService Error: $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': 'Something went wrong. Please try again.',
      };
    }
  }
}