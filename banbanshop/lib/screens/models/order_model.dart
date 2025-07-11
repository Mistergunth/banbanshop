// lib/screens/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/order_item_model.dart';

enum OrderStatus {
  pending,      // รอดำเนินการ (ใหม่)
  processing,   // กำลังเตรียมสินค้า
  shipped,      // จัดส่งแล้ว
  delivered,    // ส่งสำเร็จ
  cancelled,    // ยกเลิกแล้ว
}

// Helper extension to convert enum to string and back
extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending:
        return 'ใหม่';
      case OrderStatus.processing:
        return 'กำลังดำเนินการ';
      case OrderStatus.shipped:
        return 'จัดส่งแล้ว';
      case OrderStatus.delivered:
        return 'สำเร็จ';
      case OrderStatus.cancelled:
        return 'ยกเลิก';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}


class Order {
  final String id;
  final String storeId;
  final String buyerId;
  final String buyerName;
  final String shippingAddress;
  final String buyerPhoneNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final Timestamp orderDate;
  // --- [NEW] Field for payment slip URL ---
  final String? paymentSlipUrl;

  Order({
    required this.id,
    required this.storeId,
    required this.buyerId,
    required this.buyerName,
    required this.shippingAddress,
    required this.buyerPhoneNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    // --- [NEW] Add to constructor ---
    this.paymentSlipUrl,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    var itemsList = data['items'] as List<dynamic>? ?? [];
    List<OrderItem> orderItems = itemsList.map((item) => OrderItem.fromMap(item)).toList();

    return Order(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'N/A',
      shippingAddress: data['shippingAddress'] ?? 'N/A',
      buyerPhoneNumber: data['buyerPhoneNumber'] ?? 'N/A',
      items: orderItems,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatusExtension.fromString(data['status'] ?? 'pending'),
      orderDate: data['orderDate'] ?? Timestamp.now(),
      // --- [NEW] Read from Firestore ---
      paymentSlipUrl: data['paymentSlipUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'shippingAddress': shippingAddress,
      'buyerPhoneNumber': buyerPhoneNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'orderDate': orderDate,
      // --- [NEW] Write to Firestore ---
      'paymentSlipUrl': paymentSlipUrl,
    };
  }
}
