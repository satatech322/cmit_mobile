class UpdateFindingInquiryModel {
  final int findingId;
  final String findings;
  final List<String> files; // List of base64-encoded image strings

  UpdateFindingInquiryModel({
    required this.findingId,
    required this.findings,
    required this.files,
  });

  /// Convert model to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      "finding_id": findingId,
      "findings": findings,
      "files": files, // API expects array of base64 strings
    };
  }
}