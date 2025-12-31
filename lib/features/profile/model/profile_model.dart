class ProfileModel {
  final String name;
  final String email;
  final String cnicNumber;
  final String cellNumber;
  final String? signature;       // Can be null
  final String? profilePicture;  // Can be null

  ProfileModel({
    required this.name,
    required this.email,
    required this.cnicNumber,
    required this.cellNumber,
    this.signature,
    this.profilePicture,
  });

  /// Factory to parse API response
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      cnicNumber: json['cnic_number'] ?? '',
      cellNumber: json['cell_number'] ?? '',
      signature: json['signature'],
      profilePicture: json['profile_picture'],
    );
  }

  /// Optional: Convert back to JSON (useful if you ever need to update profile)
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "cnic_number": cnicNumber,
      "cell_number": cellNumber,
      "signature": signature,
      "profile_picture": profilePicture,
    };
  }
}