// lib/screens/post_model.dart

// ไม่ต้อง import cloud_firestore อีกต่อไป

class Post {
  final String id;
  final String shopName;
  final DateTime createdAt; // ประเภทเป็น DateTime โดยตรง
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
    required this.createdAt, // ใช้ createdAt ที่เป็น DateTime
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, 
    required this.province,
    required this.productCategory,
    required this.ownerUid, 
  });

  // Factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก Supabase)
  factory Post.fromJson(Map<String, dynamic> json) {
    // Supabase มักจะส่ง DateTime มาเป็น String ในรูปแบบ ISO 8601
    // หรืออาจจะเป็น DateTime object โดยตรงหาก Supabase client ทำการแปลงให้แล้ว
    // ตรวจสอบประเภทของ json['createdAt'] ก่อนแปลง
    DateTime parsedCreatedAt;
    if (json['createdAt'] is String) {
      parsedCreatedAt = DateTime.parse(json['createdAt']);
    } else if (json['createdAt'] is DateTime) {
      parsedCreatedAt = json['createdAt'];
    } else {
      // กรณีที่ไม่ใช่ String หรือ DateTime (เช่น null หรือประเภทอื่น)
      // อาจจะกำหนดค่าเริ่มต้น หรือจัดการข้อผิดพลาดตามความเหมาะสม
      parsedCreatedAt = DateTime.now(); // กำหนดเป็นเวลาปัจจุบันเป็นค่าเริ่มต้น
    }

    return Post(
      id: json['id'] ?? '',
      shopName: json['shopName'] ?? '',
      createdAt: parsedCreatedAt, // ใช้ createdAt ที่แปลงแล้ว
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      avatarImageUrl: json['avatarImageUrl'] ?? '',
      province: json['province'] ?? '',
      productCategory: json['productCategory'] ?? '',
      ownerUid: json['ownerUid'] ?? '', 
    );
  }

  // Method สำหรับแปลง Post เป็น Map (สำหรับบันทึกลง Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Supabase มักจะสร้าง ID ให้อัตโนมัติเมื่อ insert
      'shopName': shopName,
      'createdAt': createdAt.toIso8601String(), // แปลง DateTime เป็น String ในรูปแบบ ISO 8601 สำหรับ Supabase
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
