// lib/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Timestamp

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type; // ประเภท/หมวดหมู่ร้านค้า
  final String? imageUrl; // URL รูปภาพหน้าร้าน
  final String location; // ตำแหน่งร้านค้า (ที่อยู่)
  final double? latitude; // เพิ่ม: Latitude ของร้านค้า (nullable)
  final double? longitude; // เพิ่ม: Longitude ของร้านค้า (nullable)
  final String openingHours; // ระยะเวลาเปิด-ปิดร้าน
  final String phoneNumber; // เพิ่ม: เบอร์โทรศัพท์ร้านค้า
  final DateTime createdAt;
  

  Store({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.location,
    this.latitude, // เพิ่มใน constructor
    this.longitude, // เพิ่มใน constructor
    required this.openingHours,
    required this.phoneNumber, // เพิ่มใน constructor
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
      latitude: (json['latitude'] as num?)?.toDouble(), // อ่านค่า latitude และแปลงเป็น double
      longitude: (json['longitude'] as num?)?.toDouble(), // อ่านค่า longitude และแปลงเป็น double
      openingHours: json['openingHours'] as String? ?? '', // ป้องกัน null
      phoneNumber: json['phoneNumber'] as String? ?? '', // อ่านค่า phoneNumber และป้องกัน null
      createdAt: parsedCreatedAt,
    );
  }

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
      'latitude': latitude, // เขียนค่า latitude
      'longitude': longitude, // เขียนค่า longitude
      'openingHours': openingHours,
      'phoneNumber': phoneNumber, // เขียนค่า phoneNumber
      'createdAt': Timestamp.fromDate(createdAt), // บันทึกเป็น Timestamp สำหรับ Firestore
    };
  }
}
