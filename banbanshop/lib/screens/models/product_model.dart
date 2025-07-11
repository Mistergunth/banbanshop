// lib/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String storeId; // --- [ADDED] To know which store this product belongs to.
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable; // สถานะ เปิด/ปิด การขายสินค้านี้
  final int stock; // จำนวนสต็อก, -1 หมายถึงไม่จำกัด
  final DateTime createdAt; // --- [ADDED] To sort products by creation time.

  Product({
    required this.id,
    required this.storeId, // --- [ADDED]
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.stock = -1, // Default to unlimited stock
    required this.createdAt, // --- [ADDED]
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      storeId: data['storeId'] ?? '', // --- [ADDED]
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'ไม่มีหมวดหมู่',
      isAvailable: data['isAvailable'] ?? true,
      stock: data['stock'] ?? -1,
      createdAt: (data['createdAt'] is Timestamp) // --- [ADDED]
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId, // --- [ADDED]
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'stock': stock,
      'createdAt': Timestamp.fromDate(createdAt), // --- [ADDED]
    };
  }
}
