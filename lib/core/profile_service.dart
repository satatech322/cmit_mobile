import 'package:cmit/core/api_service.dart';
import 'package:cmit/config/api.dart';
import 'package:cmit/features/profile/model/profile_model.dart'; // Adjust path as needed

class ProfileService {
  /// Fetch current user's profile data
  static Future<Map<String, dynamic>> getProfileData() async {
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

          return {
            'success': true,
            'message': "Profile data fetched successfully",
            'data': profile,
          };
        }
      }

      return {
        'success': false,
        'message': 'Invalid response format from server',
      };
    } catch (e, stackTrace) {
      print("ProfileService Error: $e\nStackTrace: $stackTrace");
      return {
        'success': false,
        'message': "Failed to load profile. Please try again.",
      };
    }
  }
}