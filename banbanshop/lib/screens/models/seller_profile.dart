// lib/screens/models/seller_profile.dart

// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp (ถ้าจำเป็น)

class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  String? profileImageUrl;
  bool? hasStore; // เพิ่ม: สถานะว่าผู้ขายมีร้านค้าแล้วหรือไม่
  String? storeId; // เพิ่ม: ID ของร้านค้าที่ผู้ขายเป็นเจ้าของ
  String? shopName; // เพิ่ม: ชื่อร้านค้าของผู้ขาย
  String? shopAvatarImageUrl; // เพิ่ม: URL รูปภาพ Avatar ของร้านค้า
  String? shopPhoneNumber; // เพิ่ม: เบอร์โทรศัพท์ของร้านค้า
  double? shopLatitude; // เพิ่ม: Latitude ของร้านค้า
  double? shopLongitude; // เพิ่ม: Longitude ของร้านค้า

  SellerProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.province,
    required this.password,
    required this.email,
    this.profileImageUrl,
    this.shopAvatarImageUrl, // ทำให้เป็น optional
    this.hasStore,
    this.storeId,
    this.shopName,
    this.shopPhoneNumber, // เพิ่มใน constructor
    this.shopLatitude, // เพิ่มใน constructor
    this.shopLongitude, // เพิ่มใน constructor
  });

  // Factory constructor สำหรับสร้าง SellerProfile object จาก Map (เช่นจาก Firestore)
  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      idCardNumber: json['idCardNumber'] as String? ?? '',
      province: json['province'] as String? ?? '',
      password: json['password'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      shopAvatarImageUrl: json['shopAvatarImageUrl'] as String?, // อ่านค่า shopAvatarImageUrl
      hasStore: json['hasStore'] as bool?, // อ่านค่า hasStore
      storeId: json['storeId'] as String?, // อ่านค่า storeId
      shopName: json['shopName'] as String?, // อ่านค่า shopName
      shopPhoneNumber: json['shopPhoneNumber'] as String?, // อ่านค่า shopPhoneNumber
      shopLatitude: (json['shopLatitude'] as num?)?.toDouble(), // อ่านค่า shopLatitude
      shopLongitude: (json['shopLongitude'] as num?)?.toDouble(), // อ่านค่า shopLongitude
    );
  }

  // Method สำหรับแปลง SellerProfile object เป็น Map (เพื่อบันทึกลง Firestore)
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
      'shopAvatarImageUrl': shopAvatarImageUrl, // บันทึกค่า shopAvatarImageUrl
      'shopPhoneNumber': shopPhoneNumber, // บันทึกค่า shopPhoneNumber
      'shopLatitude': shopLatitude, // บันทึกค่า shopLatitude
      'shopLongitude': shopLongitude, // บันทึกค่า shopLongitude
    };
  }

  // Extension สำหรับ copyWith (ถ้ามี) - เพื่อให้สามารถสร้าง object ใหม่โดยเปลี่ยนบางฟิลด์ได้
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
    String? shopAvatarImageUrl, // เพิ่มใน copyWith
    String? shopPhoneNumber,
    double? shopLatitude,
    double? shopLongitude,
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
      shopAvatarImageUrl: shopAvatarImageUrl ?? this.shopAvatarImageUrl, // เพิ่มใน copyWith
      shopPhoneNumber: shopPhoneNumber ?? this.shopPhoneNumber,
      shopLatitude: shopLatitude ?? this.shopLatitude,
      shopLongitude: shopLongitude ?? this.shopLongitude,
    );
  }
}
