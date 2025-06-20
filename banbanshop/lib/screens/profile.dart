// lib/profile.dart หรือ lib/models/profile.dart

class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  // คุณสามารถเพิ่มข้อมูลอื่นๆ ที่เกี่ยวข้องกับโปรไฟล์ผู้ขายได้ที่นี่
  // เช่น:
  // final String storeName;
  // final String storeAddress;
  // final String profileImageUrl;

  SellerProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.province,
    required this.password,
    required this.email,
  });
}

