// lib/screens/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable; // สถานะ เปิด/ปิด การขายสินค้านี้
  final int stock; // จำนวนสต็อก, -1 หมายถึงไม่จำกัด

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.stock = -1, // Default to unlimited stock
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'ไม่มีหมวดหมู่',
      isAvailable: data['isAvailable'] ?? true,
      stock: data['stock'] ?? -1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'stock': stock,
    };
  }
}
