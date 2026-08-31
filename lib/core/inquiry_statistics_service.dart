import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/home/model/inquiry_statistics_model.dart';
import 'package:cmit/features/offline/services/inquiry_cache_service.dart';
import 'package:cmit/features/offline/services/offline_service.dart';

class InquiryStatisticsService {
  static const String _statsTotalKey = 'cached_stats_total';
  static const String _statsPendingKey = 'cached_stats_pending';
  static const String _statsCompletedKey = 'cached_stats_completed';

  /// Fetch Inquiry Statistics with offline cache fallback
  static Future<Map<String, dynamic>> getInquiryStatistics() async {
    final hasInternet = await OfflineService.hasInternet();

    if (hasInternet) {
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

            // Cache statistics to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(_statsTotalKey, statistics.total);
            await prefs.setInt(_statsPendingKey, statistics.pending);
            await prefs.setInt(_statsCompletedKey, statistics.completed);

            return {
              'success': true,
              'message': "Inquiry statistics fetched successfully",
              'data': statistics,
              'is_cached': false,
            };
          }
        }
      } catch (e, stackTrace) {
        print("InquiryStatisticsService Error: $e\nStackTrace: $stackTrace");
      }
    }

    // Fallback 1: Try reading cached statistics from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_statsTotalKey)) {
        final total = prefs.getInt(_statsTotalKey) ?? 0;
        final pending = prefs.getInt(_statsPendingKey) ?? 0;
        final completed = prefs.getInt(_statsCompletedKey) ?? 0;

        print("📦 Loaded statistics from cache: Total=$total, Pending=$pending, Completed=$completed");
        return {
          'success': true,
          'message': "Loaded inquiry statistics from cache",
          'data': InquiryStatisticsModel(
            total: total,
            pending: pending,
            completed: completed,
          ),
          'is_cached': true,
        };
      }
    } catch (e) {
      print("❌ Failed to read cached statistics: $e");
    }

    // Fallback 2: Calculate statistics dynamically from cached inquiries
    try {
      final cachedInquiries = await InquiryCacheService.getCachedInquiries();
      if (cachedInquiries != null && cachedInquiries.isNotEmpty) {
        final total = cachedInquiries.length;
        final completed = cachedInquiries.where((i) {
          final s = i.status.toString().toLowerCase();
          return s == '4' || s == 'completed';
        }).length;
        final pending = total - completed;

        print("📊 Calculated statistics from ${cachedInquiries.length} cached inquiries: Total=$total, Pending=$pending, Completed=$completed");
        return {
          'success': true,
          'message': "Calculated statistics from cached inquiries",
          'data': InquiryStatisticsModel(
            total: total,
            pending: pending,
            completed: completed,
          ),
          'is_cached': true,
        };
      }
    } catch (e) {
      print("❌ Failed to calculate statistics from cache: $e");
    }

    return {
      'success': false,
      'message': hasInternet ? 'Invalid response format from server' : 'No statistics available offline',
    };
  }
}