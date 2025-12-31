class CompleteInquiryModel {
  final int inquiryId;

  CompleteInquiryModel({
    required this.inquiryId,
  });

  /// Convert model to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      "inquiry_id": inquiryId,
    };
  }

  /// Optional: Parse response if the API returns data about the completed inquiry
  factory CompleteInquiryModel.fromJson(Map<String, dynamic> json) {
    return CompleteInquiryModel(
      inquiryId: json['inquiry_id'] ?? 0,
    );
  }
}