// lib/models/buyer_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerProfile {
  final String uid; // Firebase User UID
  final String? fullName;
  final String email;
  final String? phoneNumber;
  final String? shippingAddress; // เพิ่มฟิลด์สำหรับที่อยู่จัดส่ง

  BuyerProfile({
    required this.uid,
    this.fullName,
    required this.email,
    this.phoneNumber,
    this.shippingAddress,
  });

  // Factory constructor สำหรับสร้าง BuyerProfile จาก Firestore DocumentSnapshot
  factory BuyerProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BuyerProfile(
      uid: doc.id, // UID ของผู้ใช้คือ Document ID ใน Firestore
      fullName: data['fullName'] as String?,
      email: data['email'] as String? ?? '', // ควรมี email เสมอ
      phoneNumber: data['phoneNumber'] as String?,
      shippingAddress: data['shippingAddress'] as String?,
    );
  }

  // Method สำหรับแปลง BuyerProfile เป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'shippingAddress': shippingAddress,
      // สามารถเพิ่ม field อื่นๆ ที่นี่ได้
    };
  }
}
