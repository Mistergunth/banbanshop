// lib/screens/post_model.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore Timestamp

class Post {
  final String id;
  final String shopName;
  final DateTime createdAt; // เปลี่ยนชื่อและประเภทเป็น DateTime
  final String category;
  final String title;
  final String imageUrl;
  final String avatarImageUrl; 
  final String province;
  final String productCategory;
  final String ownerUid; 

  Post({
    required this.id,
    required this.shopName,
    required this.createdAt, // เปลี่ยนเป็น createdAt
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, 
    required this.province,
    required this.productCategory,
    required this.ownerUid, 
  });

  // Factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก Firestore)
  factory Post.fromJson(Map<String, dynamic> json) {
    // แปลง Timestamp จาก Firestore เป็น DateTime
    DateTime createdAt = (json['createdAt'] as Timestamp).toDate(); 
    return Post(
      id: json['id'] ?? '',
      shopName: json['shopName'] ?? '',
      createdAt: createdAt, // ใช้ createdAt ที่แปลงแล้ว
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      avatarImageUrl: json['avatarImageUrl'] ?? '',
      province: json['province'] ?? '',
      productCategory: json['productCategory'] ?? '',
      ownerUid: json['ownerUid'] ?? '', 
    );
  }

  // Method สำหรับแปลง Post เป็น Map (สำหรับบันทึกลง Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'createdAt': Timestamp.fromDate(createdAt), // แปลง DateTime เป็น Timestamp สำหรับ Firestore
      'category': category,
      'title': title,
      'imageUrl': imageUrl,
      'avatarImageUrl': avatarImageUrl,
      'province': province,
      'productCategory': productCategory,
      'ownerUid': ownerUid, 
    };
  }
}