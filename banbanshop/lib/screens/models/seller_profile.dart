// lib/screens/models/seller_profile.dart

class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  String? profileImageUrl;
  bool? hasStore; // เพิ่มฟิลด์นี้
  String? storeId; // เพิ่มฟิลด์นี้
  String? shopName; // เพิ่มฟิลด์นี้

  SellerProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.province,
    required this.password,
    required this.email,
    this.profileImageUrl,
    this.hasStore, // ทำให้เป็น optional
    this.storeId, // ทำให้เป็น optional
    this.shopName, // ทำให้เป็น optional
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
      hasStore: json['hasStore'] as bool?, // อ่านค่า hasStore
      storeId: json['storeId'] as String?, // อ่านค่า storeId
      shopName: json['shopName'] as String?, // อ่านค่า shopName
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
      'hasStore': hasStore, // บันทึกค่า hasStore
      'storeId': storeId, // บันทึกค่า storeId
      'shopName': shopName, // บันทึกค่า shopName
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
    bool? hasStore,
    String? storeId,
    String? shopName,
  }) {
    return SellerProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      province: province ?? this.province,
      password: password ?? this.password,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasStore: hasStore ?? this.hasStore,
      storeId: storeId ?? this.storeId,
      shopName: shopName ?? this.shopName,
    );
  }
}
