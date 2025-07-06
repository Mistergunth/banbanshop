// lib/screens/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore สำหรับ Timestamp

class Post {
  final String id;
  final String shopName;
  final DateTime createdAt; // ประเภทเป็น DateTime โดยตรง
  final String category;
  final String title;
  final String? imageUrl; // ทำให้เป็น nullable
  final String? avatarImageUrl; // ทำให้เป็น nullable
  final String province;
  final String productCategory;
  final String ownerUid; // <--- ทำให้เป็น non-nullable และต้องเป็น UUID ที่ถูกต้อง
  final String storeId; // <--- เพิ่มฟิลด์นี้เข้ามาและทำให้เป็น non-nullable

  Post({
    required this.id, // ID อาจจะถูกสร้างโดย Firestore สำหรับโพสต์ใหม่
    required this.shopName,
    required this.createdAt, // ใช้ createdAt ที่เป็น DateTime
    required this.category,
    required this.title,
    this.imageUrl, // ไม่ต้อง required แล้ว
    this.avatarImageUrl, // ไม่ต้อง required แล้ว
    required this.province,
    required this.productCategory,
    required this.ownerUid, // <--- ต้อง required และต้องเป็น UUID ที่ถูกต้อง
    required this.storeId, // <--- ต้อง required
  });

  // Factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก Firestore)
  factory Post.fromJson(Map<String, dynamic> json) {
    // Firestore มักจะส่ง DateTime มาเป็น Timestamp หรือ String ในรูปแบบ ISO 8601
    DateTime parsedCreatedAt;
    if (json['created_at'] is String) {
      parsedCreatedAt = DateTime.parse(json['created_at']);
    } else if (json['created_at'] is Timestamp) {
      parsedCreatedAt = (json['created_at'] as Timestamp).toDate();
    } else {
      parsedCreatedAt = DateTime.now(); // Fallback in case of unexpected type
    }

    // ตรวจสอบ owner_uid ให้แน่ใจว่าเป็น String
    String parsedOwnerUid = json['owner_uid'] as String? ?? '';

    // ตรวจสอบ storeId ให้แน่ใจว่าเป็น String (อ่านจาก 'storeId' ที่เป็น camelCase)
    String parsedStoreId = json['storeId'] as String? ?? '';


    return Post(
      id: json['id'] as String? ?? '', // อ่านจาก 'id' ที่เราเพิ่มเข้าไปใน map ก่อนเรียก fromJson (ป้องกัน null)
      shopName: json['shop_name'] as String? ?? '',
      createdAt: parsedCreatedAt,
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String?, // อ่านจาก 'image_url' (snake_case)
      avatarImageUrl: json['avatar_image_url'] as String?, // อ่านจาก 'avatar_image_url' (snake_case)
      province: json['province'] as String? ?? '',
      productCategory: json['product_category'] as String? ?? '', // อ่านจาก 'product_category'
      ownerUid: parsedOwnerUid, // อ่านจาก 'owner_uid' (snake_case)
      storeId: parsedStoreId, // อ่านจาก 'storeId' (camelCase)
    );
  }

  // Method สำหรับแปลง Post เป็น Map (สำหรับบันทึกลง Firestore)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {
      'shop_name': shopName,
      'created_at': createdAt.toIso8601String(), // เขียนเป็น 'created_at' (ISO 8601 String)
      'category': category,
      'title': title,
      'image_url': imageUrl, // เขียนเป็น 'image_url' (snake_case)
      'avatar_image_url': avatarImageUrl, // เขียนเป็น 'avatar_image_url' (snake_case)
      'province': province,
      'product_category': productCategory,
      'owner_uid': ownerUid, // เขียนเป็น 'owner_uid' (snake_case)
      'storeId': storeId, // เขียนเป็น 'storeId' (camelCase)
    };

    // สำหรับการ insert ใหม่, Firestore ควรจะสร้าง 'id' ให้อัตโนมัติ
    // ดังนั้น, เราจะส่ง 'id' ไปก็ต่อเมื่อมันมีค่า (เช่น สำหรับการ update)
    if (id.isNotEmpty) {
      jsonMap['id'] = id;
    }

    // ไม่จำเป็นต้อง throw ArgumentError ที่นี่ เพราะควรจะตรวจสอบตั้งแต่ตอนสร้าง Post object
    return jsonMap;
  }
}
