// lib/screens/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type;
  final String? imageUrl;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final String openingHours;
  final String phoneNumber;
  final DateTime createdAt;
  final String province;
  // --- เพิ่ม Field สำหรับเรตติ้ง ---
  final double averageRating;
  final int reviewCount;
  // --------------------------------

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
    // --- เพิ่มใน Constructor ---
    this.averageRating = 0.0,
    this.reviewCount = 0,
    // -------------------------
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
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      province: data['province'] ?? '',
      // --- ดึงข้อมูลเรตติ้งจาก Firestore ---
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      // -------------------------------------
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
      'createdAt': Timestamp.fromDate(createdAt),
      'province': province,
      // --- เพิ่มข้อมูลเรตติ้ง (เผื่อใช้ในอนาคต) ---
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      // ----------------------------------------
    };
  }
}
