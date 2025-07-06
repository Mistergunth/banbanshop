// lib/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type; // ประเภท/หมวดหมู่ร้านค้า
  final String? imageUrl; // URL รูปภาพหน้าร้าน
  final String location; // ตำแหน่งร้านค้า (อาจเป็น String ง่ายๆ ก่อน)
  final String openingHours; // ระยะเวลาเปิด-ปิดร้าน (String ง่ายๆ ก่อน)
  final DateTime createdAt;

  Store({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.location,
    required this.openingHours,
    required this.createdAt,
  });

  // Factory constructor สำหรับสร้าง Store จาก Map (เช่น จาก Firestore)
  factory Store.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreatedAt;
    if (json['createdAt'] is String) { // ตรวจสอบว่า 'createdAt' เป็น String
      parsedCreatedAt = DateTime.parse(json['createdAt']);
    } else if (json['createdAt'] is Timestamp) { // ตรวจสอบว่า 'createdAt' เป็น Timestamp
      parsedCreatedAt = (json['createdAt'] as Timestamp).toDate();
    } else {
      parsedCreatedAt = DateTime.now(); // Fallback
    }

    return Store(
      id: json['id'] as String? ?? '', // ป้องกัน null
      ownerUid: json['ownerUid'] as String? ?? '', // ป้องกัน null
      name: json['name'] as String? ?? '', // ป้องกัน null
      description: json['description'] as String? ?? '', // ป้องกัน null
      type: json['type'] as String? ?? '', // ป้องกัน null
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String? ?? '', // ป้องกัน null
      openingHours: json['openingHours'] as String? ?? '', // ป้องกัน null
      createdAt: parsedCreatedAt,
    );
  }

  get locationAddress => null;

  get phoneNumber => null;

  double? get latitude => null;

  double? get longitude => null;

  // Method สำหรับแปลง Store เป็น Map (สำหรับบันทึกลง Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'location': location,
      'openingHours': openingHours,
      'createdAt': createdAt.toIso8601String(), // บันทึกเป็น ISO 8601 String
    };
  }
}
