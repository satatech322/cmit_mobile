import 'package:cmit/features/home/model/assign_to_me_model.dart';

class InquiryPermissions {
  // Check if user can finalize the inquiry
  static bool canFinalizeInquiry(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Check if user can add field visits
  static bool canAddFieldVisit(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Check if user can finalize findings
  static bool canFinalizeFindings(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // ✅ UPDATED: Only the user who created the finding can edit it
  // Chairperson CANNOT edit other users' findings
  static bool canEditFinding(AssignToMeModel inquiry, {String? findingUserId, String? currentUserId}) {
    print("🔍 Permission Check - canEditFinding:");
    print("  - Finding User ID: '$findingUserId'");
    print("  - Current User ID: '$currentUserId'");

    // Only allow editing if the current user created this finding
    if (findingUserId != null && currentUserId != null) {
      // Ensure both are non-empty
      if (findingUserId.isNotEmpty && currentUserId.isNotEmpty) {
        final matches = findingUserId == currentUserId;
        print("  ${matches ? '✅ Access granted' : '❌ Access denied'}: User ID match = $matches");
        return matches;
      }
    }

    print("  ❌ Access denied: No valid user ID match");
    return false;
  }

  // Check if user can add annex
  static bool canAddAnnex(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Check if user can add attachment to annex
  static bool canAddAttachmentToAnnex(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Check if user can edit annex
  static bool canEditAnnex(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Check if user can view finalized inquiries (optional, for future filtering)
  static bool canViewFinalizedInquiry(AssignToMeModel inquiry) {
    return inquiry.isChairperson;
  }

  // Generic permission check with custom condition
  static bool hasPermission(AssignToMeModel inquiry, bool Function(AssignToMeModel) condition) {
    return condition(inquiry);
  }
}