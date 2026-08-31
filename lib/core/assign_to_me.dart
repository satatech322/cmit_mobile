import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/home/model/assign_to_me_model.dart';
import 'package:cmit/features/offline/services/inquiry_cache_service.dart';
import 'package:cmit/features/offline/services/offline_service.dart';

class AssignToMe {
  /// ✅ Fetch Inquiries Assigned to User with automatic offline caching and fallback
  static Future<Map<String, dynamic>> getAssignedInquiries() async {
    final hasInternet = await OfflineService.hasInternet();

    if (hasInternet) {
      try {
        print("🔹 Fetching assigned inquiries from: ${API.assignToMe}");
        final response = await ApiService.get(
          API.assignToMe,
          withAuth: true,
        );

        print("🔹 API AssignToMe Response: ${response.toString()}");

        // Check success and extract data
        if (response['success'] == true && response.containsKey('data')) {
          final nestedData = response['data'] as Map<String, dynamic>;
          if (nestedData['success'] == true && nestedData.containsKey('data')) {
            final responseData = nestedData['data'] as List<dynamic>;

            // Convert list of inquiries to AssignToMeModel
            final inquiries = responseData
                .map((json) => AssignToMeModel.fromJson(json as Map<String, dynamic>))
                .toList();

            // Cache inquiries for offline access
            await InquiryCacheService.cacheInquiries(inquiries);

            return {
              'success': true,
              'message': "Inquiries fetched successfully",
              'inquiries': inquiries,
              'is_cached': false,
            };
          }
        }
      } catch (e, stackTrace) {
        print("❌ AssignToMe API error, falling back to cache: $e\nStackTrace: $stackTrace");
      }
    }

    // Fallback to offline cache if no internet or API failed
    try {
      final cachedInquiries = await InquiryCacheService.getCachedInquiries();
      if (cachedInquiries != null && cachedInquiries.isNotEmpty) {
        print("📦 Loaded ${cachedInquiries.length} inquiries from offline cache");
        return {
          'success': true,
          'message': "Loaded inquiries from offline cache",
          'inquiries': cachedInquiries,
          'is_cached': true,
        };
      }
    } catch (e) {
      print("❌ Failed to read cached inquiries: $e");
    }

    return {
      'success': false,
      'message': hasInternet
          ? "Failed to fetch assigned inquiries."
          : "You are offline and no cached inquiries were found.",
      'inquiries': <AssignToMeModel>[],
      'is_cached': false,
    };
  }
}