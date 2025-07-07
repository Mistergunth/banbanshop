// lib/screens/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type; // ประเภท/หมวดหมู่ร้านค้า
  final String? imageUrl; // URL รูปภาพหน้าร้าน
  final String locationAddress; // ที่อยู่ร้านค้า
  final double? latitude; // ละติจูดของร้านค้า
  final double? longitude; // ลองจิจูดของร้านค้า
  final String openingHours; // ระยะเวลาเปิด-ปิดร้าน
  final String phoneNumber; // เบอร์โทรศัพท์ร้านค้า
  final DateTime createdAt; // วันที่สร้างร้านค้า

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
  });

  // Factory constructor สำหรับสร้าง Store จาก Firestore DocumentSnapshot
  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // ตรวจสอบและแปลง Timestamp เป็น DateTime
    DateTime parsedCreatedAt;
    if (data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      // Fallback หรือจัดการกรณีที่ข้อมูลไม่ใช่ Timestamp
      parsedCreatedAt = DateTime.now();
      print('Warning: createdAt field is not a Timestamp. Using current time.');
    }

    return Store(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      locationAddress: data['locationAddress'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      openingHours: data['openingHours'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      createdAt: parsedCreatedAt,
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
    };
  }
}
