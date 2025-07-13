// lib/models/product_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isAvailable; 
  final int stock; 
  final DateTime createdAt;

  Product({
    required this.id,
    required this.storeId, 
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.stock = -1, 
    required this.createdAt, 
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      storeId: data['storeId'] ?? '', 
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'ไม่มีหมวดหมู่',
      isAvailable: data['isAvailable'] ?? true,
      stock: data['stock'] ?? -1,
      createdAt: (data['createdAt'] is Timestamp) 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId, 
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'stock': stock,
      'createdAt': Timestamp.fromDate(createdAt), 
    };
  }
}
