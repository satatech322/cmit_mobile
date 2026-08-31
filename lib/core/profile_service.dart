import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/core/local_storage.dart';
import 'package:cmit/features/offline/services/offline_service.dart';
import 'package:cmit/features/profile/model/profile_model.dart';

class ProfileService {
  static const String _profileCacheKey = 'cached_profile_data';

  /// Fetch current user's profile data with offline cache fallback
  static Future<Map<String, dynamic>> getProfileData() async {
    final hasInternet = await OfflineService.hasInternet();

    if (hasInternet) {
      try {
        print("Fetching profile data from: /api/v1/get/profile/data");

        final response = await ApiService.get(
          "${ApiConfig.baseApiUrl}/get/profile/data",
          withAuth: true,
        );

        print("API Profile Raw Response: $response");

        if (response['success'] == true && response.containsKey('data')) {
          var rawData = response['data'];

          // Handle nested structure: {success: true, data: {success: true, data: {...}}}
          if (rawData is Map<String, dynamic> && rawData.containsKey('success') && rawData.containsKey('data')) {
            print("Detected nested data structure, extracting inner data...");
            rawData = rawData['data'];
          }

          if (rawData is Map<String, dynamic>) {
            print("Parsing profile data: $rawData");
            final profile = ProfileModel.fromJson(rawData);

            // Cache profile data for offline access
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_profileCacheKey, jsonEncode(rawData));
            } catch (e) {
              print("Failed to save profile to cache: $e");
            }

            return {
              'success': true,
              'message': "Profile data fetched successfully",
              'data': profile,
              'is_cached': false,
            };
          }
        }
      } catch (e, stackTrace) {
        print("ProfileService Error: $e\nStackTrace: $stackTrace");
      }
    }

    // Fallback 1: Load cached profile data
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_profileCacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final rawData = jsonDecode(cachedJson) as Map<String, dynamic>;
        final profile = ProfileModel.fromJson(rawData);
        print("👤 Loaded profile from offline cache: ${profile.name}");
        return {
          'success': true,
          'message': "Profile loaded from offline cache",
          'data': profile,
          'is_cached': true,
        };
      }
    } catch (e) {
      print("❌ Failed to parse cached profile: $e");
    }

    // Fallback 2: Construct basic profile from LocalStorage credentials
    try {
      final userName = await LocalStorage.getUserName();
      if (userName != null && userName.isNotEmpty) {
        final fallbackProfile = ProfileModel(
          name: userName,
          email: 'Offline Mode',
          cnicNumber: 'N/A',
          cellNumber: 'N/A',
          profilePicture: null,
        );
        return {
          'success': true,
          'message': "Basic profile loaded offline",
          'data': fallbackProfile,
          'is_cached': true,
        };
      }
    } catch (e) {
      print("❌ Failed to load basic fallback profile: $e");
    }

    return {
      'success': false,
      'message': hasInternet
          ? "Failed to load profile. Please try again."
          : "You are offline and no cached profile data was found.",
    };
  }
}