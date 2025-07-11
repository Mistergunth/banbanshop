// lib/models/cart_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String storeId;
  final String name;
  final String? imageUrl;
  final double price;
  int quantity;
  final Timestamp addedAt;

  CartItem({
    required this.productId,
    required this.storeId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.addedAt,
  });

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CartItem(
      productId: doc.id,
      storeId: data['storeId'] ?? '',
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: data['quantity'] ?? 0,
      addedAt: data['addedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }
}
