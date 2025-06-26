// import 'package:flutter/material.dart'; // ลบการ import นี้ออกเนื่องจากไม่ได้ใช้งาน

class Post {
  final String id;
  final String shopName;
  final String timeAgo;
  final String category;
  final String title;
  final String imageUrl;
  final String avatarImageUrl; 
  final String province;
  final String productCategory;

  Post({
    required this.id,
    required this.shopName,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, 
    required this.province,
    required this.productCategory,
  });

  // เพิ่ม factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก JSON/Firestore)
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      shopName: json['shopName'],
      timeAgo: json['timeAgo'],
      category: json['category'],
      title: json['title'],
      imageUrl: json['imageUrl'],
      avatarImageUrl: json['avatarImageUrl'],
      province: json['province'],
      productCategory: json['productCategory'],
    );
  }

  // เพิ่ม method สำหรับแปลง Post เป็น Map (เช่น สำหรับบันทึกลง JSON/Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'timeAgo': timeAgo,
      'category': category,
      'title': title,
      'imageUrl': imageUrl,
      'avatarImageUrl': avatarImageUrl,
      'province': province,
      'productCategory': productCategory,
    };
  }
}
