// lib/screens/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String ownerUid;
  final String name; // ชื่อร้านค้า
  final String description; // คำอธิบายร้าน
  final String type; // ประเภท/หมวดหมู่ร้านค้า
  final String? imageUrl; // URL รูปภาพหน้าร้าน
  final String locationAddress; // ที่อยู่ร้านค้า
  final double? latitude; // ละติจูดของร้านค้า
  final double? longitude; // ลองจิจูดของร้านค้า
  final String openingHours; // ระยะเวลาเปิด-ปิดร้าน
  final String phoneNumber; // เบอร์โทรศัพท์ร้านค้า
  final DateTime createdAt; // วันที่สร้างร้านค้า
  final String province; // เพิ่มจังหวัดเข้ามาให้สอดคล้องกับระบบ

  Store({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.openingHours,
    required this.phoneNumber,
    required this.createdAt,
    required this.province,
  });

  // Factory constructor สำหรับสร้าง Store จาก Firestore DocumentSnapshot
  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Store(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      imageUrl: data['imageUrl'],
      locationAddress: data['locationAddress'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      openingHours: data['openingHours'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      // ตรวจสอบและแปลง Timestamp เป็น DateTime อย่างปลอดภัย
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      province: data['province'] ?? '', // ดึงข้อมูลจังหวัด
    );
  }

  // Method สำหรับแปลง Store เป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt), // ใช้ Timestamp สำหรับ Firestore
      'province': province,
    };
  }
}