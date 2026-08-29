import 'package:cmit/core/api_service.dart';
import 'package:cmit/core/local_storage.dart';
import 'package:cmit/features/auth/model/login_model.dart';
import 'package:cmit/config/api.dart';

class AuthService {
  /// ✅ **User Login (Supports flat and nested API response structures)**
  static Future<Map<String, dynamic>> login(LoginModel user) async {
    try {
      final response = await ApiService.post(
        API.login,
        user.toJson(),
        withAuth: false,
      );

      print("🔹 API Login Response: ${response.toString()}");

      // Check if API call returned a response
      if (response['success'] == true && response.containsKey('data')) {
        final responseData = response['data'];

        if (responseData is Map) {
          // 1. Extract Token
          String? token;
          if (responseData['token'] is String && (responseData['token'] as String).isNotEmpty) {
            token = responseData['token'];
          } else if (responseData['data'] is Map && responseData['data']['token'] is String && (responseData['data']['token'] as String).isNotEmpty) {
            token = responseData['data']['token'];
          }

          // 2. Extract User Data
          Map<String, dynamic>? userData;
          if (responseData['data'] is Map<String, dynamic>) {
            userData = Map<String, dynamic>.from(responseData['data']);
          } else if (responseData['data'] is Map) {
            userData = Map<String, dynamic>.from(responseData['data'] as Map);
          } else if (responseData['user'] is Map) {
            userData = Map<String, dynamic>.from(responseData['user'] as Map);
          }

          // 3. Evaluate Status & Codes
          final dynamic status = responseData['status'];
          final dynamic responseCode = responseData['response_Code'] ?? responseData['response_code'] ?? responseData['responseCode'];

          final bool isStatusSuccess = status == true || status == 1 || status == '1' || status == 'true' || status == 'success';
          final bool isCodeSuccess = responseCode == '00' || responseCode == 0 || responseCode == '0' || responseCode == 200 || responseCode == '200';

          // If token is present and no failure was indicated
          if (token != null && (isStatusSuccess || isCodeSuccess || (status == null && responseCode == null))) {
            await LocalStorage.saveToken(token);
            if (userData != null) {
              await LocalStorage.saveUser(userData);
            }

            final successMessage = ApiService.extractErrorMessage(
              responseData,
              defaultMessage: "Login successful",
            );

            return {
              'success': true,
              'message': successMessage,
              'token': token,
              if (userData != null) 'user': userData,
            };
          } else {
            // Failed response from backend (e.g. invalid credentials)
            final errorMessage = ApiService.extractErrorMessage(
              responseData,
              defaultMessage: "Invalid login credentials.",
            );

            return {
              'success': false,
              'message': errorMessage,
            };
          }
        }
      }

      // Handle failure case (e.g. network/server error or 4xx/5xx responses)
      final errorMessage = ApiService.extractErrorMessage(
        response['data'] ?? response,
        defaultMessage: response['message']?.toString() ?? "Invalid email or password.",
      );

      return {
        'success': false,
        'message': errorMessage,
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