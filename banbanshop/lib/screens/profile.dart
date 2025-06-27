// lib/profile.dart หรือ lib/models/profile.dart

class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  String? profileImageUrl; // Field นี้มีอยู่แล้ว

  SellerProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.province,
    required this.password,
    required this.email,
    this.profileImageUrl,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      idCardNumber: json['idCardNumber'] ?? '',
      province: json['province'] ?? '',
      password: json['password'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'idCardNumber': idCardNumber,
      'province': province,
      'password': password,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }
}

// Extension สำหรับ copyWith (ถ้ามี)
extension SellerProfileCopyWith on SellerProfile {
  SellerProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? idCardNumber,
    String? province,
    String? password,
    String? email,
    String? profileImageUrl,
  }) {
    return SellerProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      province: province ?? this.province,
      password: password ?? this.password,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}