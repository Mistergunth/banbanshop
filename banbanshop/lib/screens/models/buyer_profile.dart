// lib/models/buyer_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerProfile {
  final String uid; // Firebase User UID
  final String? fullName;
  final String email;
  final String? phoneNumber;
  final String? shippingAddress;
  final String? profileImageUrl; 
  final String? idCardNumber;

  BuyerProfile({
    required this.uid,
    this.fullName,
    required this.email,
    this.phoneNumber,
    this.shippingAddress,
    this.profileImageUrl,
    this.idCardNumber, // <--- เพิ่มใน constructor
  });

  // Factory constructor สำหรับสร้าง BuyerProfile จาก Firestore DocumentSnapshot
  factory BuyerProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BuyerProfile(
      uid: doc.id, // UID ของผู้ใช้คือ Document ID ใน Firestore
      fullName: data['fullName'] as String?,
      email: data['email'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      shippingAddress: data['shippingAddress'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      idCardNumber: data['idCardNumber'] as String?, // <--- อ่านจาก Firestore
    );
  }

  // Method สำหรับแปลง BuyerProfile เป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'shippingAddress': shippingAddress,
      'profileImageUrl': profileImageUrl,
      'idCardNumber': idCardNumber, // <--- เขียนลง Firestore
    };
  }

  // เพิ่ม copyWith method เพื่อให้แก้ไขข้อมูลได้ง่ายขึ้น
  BuyerProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? shippingAddress,
    String? profileImageUrl,
    String? idCardNumber,
  }) {
    return BuyerProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      idCardNumber: idCardNumber ?? this.idCardNumber,
    );
  }
}
