class ApiConfig {
  // Centralized base URL - change this when needed
  static const String _baseUrl = "https://cmit.sata.pk/api/v1";

  // For assets like department_logo
  static const String assetBaseUrl = "$_baseUrl";

  // Full API base URL
  static const String baseApiUrl = _baseUrl;
}

class API {
  // 🔹 Authentication Endpoints
  static const String login = "${ApiConfig.baseApiUrl}/login";
  static const String logout = "${ApiConfig.baseApiUrl}/logout";

  // 🔹 Inquiry Endpoints
  static const String assignToMe = "${ApiConfig.baseApiUrl}/get/inquiry/assigned-to-me";

  // 🔹 Recommendation Inquiry Endpoint (New)
  static const String addRecommendationInquiry = "${ApiConfig.baseApiUrl}/add/recommendation/inquiries";

  // Inside class API
  static const String getVehicleDriverData = "${ApiConfig.baseApiUrl}/get/vehicle/driver/data";
  // Inside class API
  static const String addVisitInquiry = "${ApiConfig.baseApiUrl}/add/visits/inquiries";

  // Inside class API
  static const String storeFindingInquiry = "${ApiConfig.baseApiUrl}/store/finding/inquiries";
  static const String getDocumentTypes = "${ApiConfig.baseApiUrl}/get/document-types";
  static const String storeRequiredDocuments = "${ApiConfig.baseApiUrl}/store/required-documents/inquiries";
  // Inside class API
  static const String uploadRequiredDocuments = "${ApiConfig.baseApiUrl}/upload/required-documents/inquiries";
  // Inside class API (add this line)
  static const String storeAnnex = "${ApiConfig.baseApiUrl}/store/annex";

  // Inside class API (add this line)
  static const String uploadAnnexFile = "${ApiConfig.baseApiUrl}/upload/annex/file";

  static const String storeFinalizedFindingInquiry = "${ApiConfig.baseApiUrl}/store/finding/finalized/inquiries";

  // Inside class API (add this line)
  static const String getInquiryStatistics = "${ApiConfig.baseApiUrl}/get/inquiry/statistics";

  static const String updateFindingInquiry = "${ApiConfig.baseApiUrl}/update/finding/inquiries";

  // Inside class API
  static const String getProfileData = "${ApiConfig.baseApiUrl}/get/profile/data";

  static const String completeInquiry = "${ApiConfig.baseApiUrl}/store/complete/inquiries";

}