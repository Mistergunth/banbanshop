// lib/screens/buyer/buyer_orders_screen.dart

import 'package:banbanshop/screens/buyer/buyer_pickup_tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:banbanshop/screens/buyer/buyer_live_tracking_screen.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<Order>> _getBuyerOrdersStream() {
    if (_currentUser == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('buyerId', isEqualTo: _currentUser.uid)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการสั่งซื้อของฉัน'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
      ),
      body: _currentUser == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อดูรายการสั่งซื้อ'))
          : StreamBuilder<List<Order>>(
              stream: _getBuyerOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))); // Blue loading
                }
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt_rounded, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('คุณยังไม่มีรายการสั่งซื้อ', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return BuyerOrderCard(order: order);
                  },
                );
              },
            ),
    );
  }
}

class BuyerOrderCard extends StatelessWidget {
  final Order order;

  const BuyerOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm', 'th');
    final bool isReadyForAction = order.status == OrderStatus.shipped;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3, // Added elevation
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ออเดอร์ #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87), // Larger, darker text
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    order.status.name,
                    style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.calendar_today_outlined, 'วันที่สั่ง:', formatter.format(order.orderDate.toDate())),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.receipt_long_outlined, 'ยอดรวม:', '฿${order.totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildInfoRow(
              order.deliveryMethod == 'pickup' ? Icons.store_mall_directory_outlined : Icons.local_shipping_outlined,
              'วิธีจัดส่ง:',
              order.deliveryMethod == 'pickup' ? 'รับที่ร้าน' : 'จัดส่ง',
            ),
            
            if (isReadyForAction) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: order.deliveryMethod == 'pickup'
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.pin_drop_outlined),
                        label: const Text('เริ่มแชร์ตำแหน่งเพื่อไปรับสินค้า'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyerPickupTrackingScreen(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1), // Blue button
                          foregroundColor: Colors.white,
                        ),
                      )
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.track_changes_rounded),
                        label: const Text('ติดตามการจัดส่ง'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyerLiveTrackingScreen(order: order),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A00E0), // Dark Purple button
                          foregroundColor: Colors.white,
                        ),
                      ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Darker text
        const SizedBox(width: 4),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
      ],
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return const Color(0xFF4A00E0); // Dark Purple for shipped
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
