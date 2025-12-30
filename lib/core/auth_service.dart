import 'package:cmit/core/api_service.dart';
import 'package:cmit/core/local_storage.dart';
import 'package:cmit/features/auth/model/login_model.dart';
import 'package:cmit/config/api.dart';

class AuthService {
  /// ✅ **User Login (Updated for Nested API Response Structure)**
  static Future<Map<String, dynamic>> login(LoginModel user) async {
    try {
      final response = await ApiService.post(
        API.login,
        user.toJson(),
        withAuth: false,
      );

      print("🔹 API Login Response: ${response.toString()}");

      // ✅ Check success and extract data
      if (response['success'] == true && response.containsKey('data')) {
        final responseData = response['data'];

        // ✅ Extract user and token from nested structure
        if (responseData['status'] == true && responseData.containsKey('data') && responseData.containsKey('token')) {
          final userData = responseData['data'] as Map<String, dynamic>;
          final token = responseData['token'] as String;

          // ✅ Save token & user details
          await LocalStorage.saveToken(token);
          await LocalStorage.saveUser(userData);

          return {
            'success': true,
            'message': responseData['message'] ?? "Login successful",
            'token': token,
            'user': userData,
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? "Invalid response structure from server."
          };
        }
      }

      // Handle failure case
      return {
        'success': false,
        'message': response['message'] ?? "Invalid email or password."
      };
    } catch (e, stackTrace) {
      print("❌ AuthService: Login Error - $e\nStackTrace: $stackTrace");
      return {'success': false, 'message': "A network error occurred. Please try again."};
    }
  }

  /// ✅ **Check if User is Logged In**
  static Future<bool> isLoggedIn() async {
    try {
      String? token = await LocalStorage.getToken();
      print("🔹 Checking login status. Token found: $token");
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("❌ AuthService: isLoggedIn Error - $e");
      return false;
    }
  }

  /// ✅ **Get Current User Data**
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final userData = await LocalStorage.getUser();
      print("🔹 Current user data: $userData");
      return userData;
    } catch (e) {
      print("❌ AuthService: getCurrentUser Error - $e");
      return null;
    }
  }

  /// ✅ **Get Current User ID**
  static Future<String?> getCurrentUserId() async {
    try {
      final userData = await LocalStorage.getUser();

      if (userData != null) {
        // Try different possible ID field names from API
        final userId = userData['id']?.toString() ??
            userData['user_id']?.toString() ??
            userData['userId']?.toString();

        print("🔹 Current user ID: $userId");
        return userId;
      }

      print("⚠️ No user data found");
      return null;
    } catch (e) {
      print("❌ AuthService: getCurrentUserId Error - $e");
      return null;
    }
  }

  /// ✅ **Get Current User Name**
  static Future<String?> getCurrentUserName() async {
    try {
      final userData = await LocalStorage.getUser();

      if (userData != null) {
        // Try different possible name field names from API
        final userName = userData['name']?.toString() ??
            userData['username']?.toString() ??
            userData['full_name']?.toString();

        print("🔹 Current user name: $userName");
        return userName;
      }

      return null;
    } catch (e) {
      print("❌ AuthService: getCurrentUserName Error - $e");
      return null;
    }
  }

  /// ✅ **Logout (Ensures API Call & Clears Token)**
  static Future<bool> logout() async {
    try {
      final response = await ApiService.post(API.logout, {}, withAuth: true);

      print("🔹 Logout API Response: $response");

      if (response['success'] == true) {
        await LocalStorage.logout();

        // ✅ Check if token is actually removed
        String? tokenCheck = await LocalStorage.getToken();
        print("🔹 Token after logout: $tokenCheck");

        if (tokenCheck == null || tokenCheck.isEmpty) {
          print("✅ Logout successful & token cleared!");
          return true;
        } else {
          print("❌ Token was not removed properly!");
          return false;
        }
      }

      print("❌ Logout API failed: ${response['message']}");
      return false;
    } catch (e) {
      print("❌ AuthService: Logout Error - $e");
      return false;
    }
  }
}