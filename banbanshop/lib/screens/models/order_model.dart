// lib/screens/models/order_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/order_item_model.dart';

enum DeliveryMethod { delivery, pickup }
enum PaymentMethod { transfer, cod }

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.pending: return 'ใหม่';
      case OrderStatus.processing: return 'กำลังดำเนินการ';
      case OrderStatus.shipped: return 'จัดส่งแล้ว';
      case OrderStatus.delivered: return 'สำเร็จ';
      case OrderStatus.cancelled: return 'ยกเลิก';
    }
  }
  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere((e) => e.toString().split('.').last == status, orElse: () => OrderStatus.pending);
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
  final String? paymentSlipUrl;
  
  // --- Fields for IN-APP Live Tracking ---
  final GeoPoint? delivererLocation; 
  final Timestamp? lastLocationUpdate; 
  // --- [NEW] Field for the destination address coordinates ---
  final GeoPoint? shippingLocation; 

  final String deliveryMethod;
  final String paymentMethod;

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
    this.paymentSlipUrl,
    this.delivererLocation,
    this.lastLocationUpdate,
    // --- [NEW] Add to constructor ---
    this.shippingLocation,
    this.deliveryMethod = 'delivery',
    this.paymentMethod = 'transfer',
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
      paymentSlipUrl: data['paymentSlipUrl'],
      delivererLocation: data['delivererLocation'] as GeoPoint?,
      lastLocationUpdate: data['lastLocationUpdate'] as Timestamp?,
      // --- [NEW] Read from Firestore ---
      shippingLocation: data['shippingLocation'] as GeoPoint?,
      deliveryMethod: data['deliveryMethod'] ?? 'delivery',
      paymentMethod: data['paymentMethod'] ?? 'transfer',
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
      'paymentSlipUrl': paymentSlipUrl,
      'delivererLocation': delivererLocation,
      'lastLocationUpdate': lastLocationUpdate,
      // --- [NEW] Write to Firestore ---
      'shippingLocation': shippingLocation,
      'deliveryMethod': deliveryMethod,
      'paymentMethod': paymentMethod,
    };
  }

  Order copyWith({
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      storeId: storeId,
      buyerId: buyerId,
      buyerName: buyerName,
      shippingAddress: shippingAddress,
      buyerPhoneNumber: buyerPhoneNumber,
      items: items,
      totalAmount: totalAmount,
      status: status ?? this.status,
      orderDate: orderDate,
      paymentSlipUrl: paymentSlipUrl,
      delivererLocation: delivererLocation,
      lastLocationUpdate: lastLocationUpdate,
      shippingLocation: shippingLocation,
      deliveryMethod: deliveryMethod,
      paymentMethod: paymentMethod,
    );
  }
}
