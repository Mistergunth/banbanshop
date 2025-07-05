// lib/screens/post_model.dart

// ไม่ต้อง import cloud_firestore อีกต่อไป

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

  Post({
    required this.id, // ID อาจจะถูกสร้างโดย Supabase สำหรับโพสต์ใหม่
    required this.shopName,
    required this.createdAt, // ใช้ createdAt ที่เป็น DateTime
    required this.category,
    required this.title,
    this.imageUrl, // ไม่ต้อง required แล้ว
    this.avatarImageUrl, // ไม่ต้อง required แล้ว
    required this.province,
    required this.productCategory,
    required this.ownerUid, // <--- ต้อง required และต้องเป็น UUID ที่ถูกต้อง
  });

  // Factory constructor สำหรับสร้าง Post จาก Map (เช่น จาก Supabase)
  factory Post.fromJson(Map<String, dynamic> json) {
    // Supabase มักจะส่ง DateTime มาเป็น String ในรูปแบบ ISO 8601
    DateTime parsedCreatedAt;
    if (json['created_at'] is String) { // ใช้ created_at (snake_case)
      parsedCreatedAt = DateTime.parse(json['created_at']);
    } else if (json['created_at'] is DateTime) { // ใช้ created_at (snake_case)
      parsedCreatedAt = json['created_at'];
    } else {
      parsedCreatedAt = DateTime.now(); // กำหนดเป็นเวลาปัจจุบันเป็นค่าเริ่มต้น
    }

    // owner_uid ควรจะถูกส่งมาเสมอ แต่ถ้าเป็น null ให้ใช้ค่าว่าง (ซึ่งจะทำให้เกิด error ถ้า DB เป็น UUID NOT NULL)
    // ปัญหานี้มักจะเกิดจากการที่ ownerUid ไม่ได้ถูกกำหนดค่าที่ถูกต้องตั้งแต่แรก
    final String parsedOwnerUid = json['owner_uid'] as String? ?? '';

    return Post(
      id: json['id'] as String? ?? '', // ID อาจเป็น null ได้ถ้า Supabase สร้างให้
      shopName: json['shop_name'] as String? ?? '', // **แก้ไขตรงนี้: อ่านจาก 'shop_name'**
      createdAt: parsedCreatedAt, // ใช้ createdAt ที่แปลงแล้ว
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String?, // อ่านจาก 'image_url' (snake_case)
      avatarImageUrl: json['avatar_image_url'] as String?, // อ่านจาก 'avatar_image_url' (snake_case)
      province: json['province'] as String? ?? '',
      productCategory: json['product_category'] as String? ?? '', // **แก้ไขตรงนี้: อ่านจาก 'product_category'**
      ownerUid: parsedOwnerUid, // อ่านจาก 'owner_uid' (snake_case)
    );
  }

  // Method สำหรับแปลง Post เป็น Map (สำหรับบันทึกลง Supabase)
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
    };

    // สำหรับการ insert ใหม่, Supabase ควรจะสร้าง 'id' ให้อัตโนมัติ
    // ดังนั้น, เราจะส่ง 'id' ไปก็ต่อเมื่อมันมีค่า (เช่น สำหรับการ update)
    if (id.isNotEmpty) {
      jsonMap['id'] = id;
    }

    // สำคัญ: 'owner_uid' ต้องเป็น UUID ที่ถูกต้องเสมอ
    // หาก ownerUid เป็นค่าว่าง, แสดงว่ามีปัญหาในการดึง ID ผู้ใช้
    if (ownerUid.isEmpty) {
      // ในกรณีนี้, เราจะ throw ArgumentError เพื่อให้เห็นปัญหาชัดเจน
      // คุณต้องแน่ใจว่า ownerUid ถูกกำหนดค่าที่ถูกต้องก่อนที่จะเรียก toJson()
      throw ArgumentError('ownerUid must not be empty. Please ensure the user is logged in and their ID is retrieved before creating a post.');
    }
    jsonMap['owner_uid'] = ownerUid; // <--- สำคัญ: เขียนเป็น 'owner_uid' (snake_case)

    return jsonMap;
  }
}