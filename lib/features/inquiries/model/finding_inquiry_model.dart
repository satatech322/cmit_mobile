// lib/features/inquiries/model/finding_inquiry_model.dart

class FindingInquiryModel {
  final String findings;
  final int visitId;
  final List<String>? files; // List of Base64-encoded image strings (can be null)

  FindingInquiryModel({
    required this.findings,
    required this.visitId,
    this.files,
  });

  /// Convert model to JSON map for API request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      "visit_id": visitId,
      "findings": findings,
    };

    // Only add 'files' if it's not null and not empty
    if (files != null && files!.isNotEmpty) {
      json["files"] = files;
    }

    return json;
  }

  /// Create model instance from JSON response (e.g., after successful save)
  factory FindingInquiryModel.fromJson(Map<String, dynamic> json) {
    return FindingInquiryModel(
      findings: json['findings'] as String? ?? '',
      visitId: json['visit_id'] as int? ?? 0,
      files: json['files'] != null
          ? List<String>.from(json['files'] as List<dynamic>)
          : null,
    );
  }

  /// Optional: Helpful for debugging or logging
  @override
  String toString() {
    return 'FindingInquiryModel(findings: $findings, visitId: $visitId, filesCount: ${files?.length ?? 0})';
  }
}