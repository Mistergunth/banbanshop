// lib/screens/profile.dart

class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  String? profileImageUrl;

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
    // แก้ไข: อ่านข้อมูลจาก Supabase โดยใช้ snake_case keys
    return SellerProfile(
      fullName: json['full_name'] as String? ?? '', // เปลี่ยนจาก 'fullName' เป็น 'full_name'
      phoneNumber: json['phone_number'] as String? ?? '', // เปลี่ยนจาก 'phoneNumber' เป็น 'phone_number'
      idCardNumber: json['id_card_number'] as String? ?? '', // เปลี่ยนจาก 'idCardNumber' เป็น 'id_card_number'
      province: json['province'] as String? ?? '',
      password: json['password'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profile_image_url'] as String? ?? '', // นี่ถูกอยู่แล้ว
    );
  }

  Map<String, dynamic> toJson() {
    // แก้ไข: เขียนข้อมูลไป Supabase โดยใช้ snake_case keys
    return {
      'full_name': fullName, // เปลี่ยนจาก 'fullName' เป็น 'full_name'
      'phone_number': phoneNumber, // เปลี่ยนจาก 'phoneNumber' เป็น 'phone_number'
      'id_card_number': idCardNumber, // เปลี่ยนจาก 'idCardNumber' เป็น 'id_card_number'
      'province': province,
      'password': password,
      'email': email,
      'profile_image_url': profileImageUrl, // เปลี่ยนจาก 'profileImageUrl' เป็น 'profile_image_url'
    };
  }
}

// Extension สำหรับ copyWith (ถ้ามี) - ตรวจสอบและแก้ไขให้ตรงกับโครงสร้างใหม่ด้วยนะครับ
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
