// lib/screens/post_model.dart

// ignore_for_file: avoid_print

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
  final String ownerUid; // <--- ทำให้เป็น non-nullable
  final String storeId; // <--- ทำให้เป็น non-nullable
  final String? productId;
  final String? productName;


  Post({
    required this.id, // ID อาจจะถูกสร้างโดย Firestore สำหรับโพสต์ใหม่
    required this.shopName,
    required this.createdAt, // ใช้ createdAt ที่เป็น DateTime
    required this.category,
    required this.title,
    this.imageUrl, // ไม่ต้อง required แล้ว
    this.avatarImageUrl, // ไม่ต้อง required แล้ว
    this.productId,
    this.productName,
    required this.province,
    required this.productCategory,
    required this.ownerUid, // <--- ต้อง required
    required this.storeId, // <--- ต้อง required
  });

  // Factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก Firestore)
  factory Post.fromJson(Map<String, dynamic> json) {
    // Firestore มักจะส่ง DateTime มาเป็น Timestamp หรือ String ในรูปแบบ ISO 8601
    DateTime parsedCreatedAt;
    if (json['created_at'] is String) { // อ่านจาก 'created_at' (snake_case)
      parsedCreatedAt = DateTime.parse(json['created_at']);
    } else if (json['created_at'] is Timestamp) {
      parsedCreatedAt = (json['created_at'] as Timestamp).toDate();
    } else {
      parsedCreatedAt = DateTime.now(); // Fallback in case of unexpected type
    }

    // อ่าน ownerUid จาก 'ownerUid' (camelCase) หรือ 'owner_uid' (snake_case)
    // เพื่อให้เข้ากันได้กับข้อมูลเก่าและใหม่
    String parsedOwnerUid = '';
    if (json.containsKey('ownerUid') && json['ownerUid'] is String) {
      parsedOwnerUid = json['ownerUid'];
    } else if (json.containsKey('owner_uid') && json['owner_uid'] is String) {
      parsedOwnerUid = json['owner_uid'];
    } else {
      print('Warning: ownerUid/owner_uid is missing or not a String: ${json['ownerUid']} / ${json['owner_uid']}');
    }

    // อ่าน storeId จาก 'storeId' (camelCase) หรือ 'store_id' (snake_case)
    String parsedStoreId = '';
    if (json.containsKey('storeId') && json['storeId'] is String) {
      parsedStoreId = json['storeId'];
    } else if (json.containsKey('store_id') && json['store_id'] is String) {
      parsedStoreId = json['store_id'];
    } else {
      print('Warning: storeId/store_id is missing or not a String: ${json['storeId']} / ${json['store_id']}');
    }


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
      ownerUid: parsedOwnerUid, // ใช้ค่าที่อ่านมา
      storeId: parsedStoreId, // ใช้ค่าที่อ่านมา
      productId: json['productId'] as String?, // อ่านจาก json โดยตรง
      productName: json['productName'] as String?, // อ่านจาก json โดยตรง
    );
  }

  // Method สำหรับแปลง Post เป็น Map (สำหรับบันทึกลง Firestore)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {
      'shop_name': shopName,
      'created_at': createdAt.toIso8601String(), // เขียนเป็น 'created_at' (snake_case)
      'category': category,
      'title': title,
      'image_url': imageUrl, // เขียนเป็น 'image_url' (snake_case)
      'avatar_image_url': avatarImageUrl, // เขียนเป็น 'avatar_image_url' (snake_case)
      'province': province,
      'product_category': productCategory,
      'ownerUid': ownerUid, // <--- เขียนเป็น 'ownerUid' (camelCase) เพื่อให้ตรงกับกฎความปลอดภัย
      'storeId': storeId, // <--- เขียนเป็น 'storeId' (camelCase) เพื่อให้ตรงกับกฎความปลอดภัย
      'productId': productId, // <--- เขียนเป็น 'storeId' (camelCase) เพื่อให้ตรงกับกฎความปลอดภัย
      'productName': productName, // <--- เขียนเป็น 'storeId' (camelCase) เพื่อให้ตรงกับกฎความปลอดภัย
    };

    // สำหรับการ insert ใหม่, Firestore ควรจะสร้าง 'id' ให้อัตโนมัติ
    // ดังนั้น, เราจะส่ง 'id' ไปก็ต่อเมื่อมันมีค่า (เช่น สำหรับการ update)
    if (id.isNotEmpty) {
      jsonMap['id'] = id;
    }

    return jsonMap;
  }
}
