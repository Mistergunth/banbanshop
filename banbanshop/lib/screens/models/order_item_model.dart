// lib/screens/models/order_item_model.dart

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  // Convert an OrderItem instance to a Map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  // Create an OrderItem instance from a Map
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
    );
  }
}
