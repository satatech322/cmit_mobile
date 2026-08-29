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

  // ✅ UPDATED: Only the user who created the finding can edit it, UNLESS findings are already finalized
  static bool canEditFinding(AssignToMeModel inquiry, {String? findingUserId, String? currentUserId}) {
    // If findings are already finalized, no one can edit findings anymore
    if (inquiry.isFindingsFinalized) {
      return false;
    }

    // Only allow editing if the current user created this finding
    if (findingUserId != null && currentUserId != null) {
      if (findingUserId.isNotEmpty && currentUserId.isNotEmpty) {
        return findingUserId == currentUserId;
      }
    }

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