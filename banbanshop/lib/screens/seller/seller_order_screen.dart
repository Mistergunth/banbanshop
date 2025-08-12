// lib/screens/seller/seller_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:banbanshop/screens/seller/order_detail_screen.dart';
import 'package:intl/intl.dart';

class SellerOrdersScreen extends StatefulWidget {
  final bool isEmbedded;

  const SellerOrdersScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _storeId;
  bool _isLoading = true;

  final List<Tab> _tabs = const [
    Tab(text: 'ใหม่'),
    Tab(text: 'กำลังดำเนินการ'),
    Tab(text: 'จัดส่งแล้ว'), 
    Tab(text: 'สำเร็จ'),
    Tab(text: 'ยกเลิก'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchUserStoreId();
  }

  Future<void> _fetchUserStoreId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
      if (mounted && sellerDoc.exists && sellerDoc.data()!.containsKey('storeId')) {
        setState(() {
          _storeId = sellerDoc.data()!['storeId'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // ignore: avoid_print
      print("Error fetching store ID: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screenContent = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
        : _storeId == null
            ? const Center(child: Text('คุณยังไม่มีร้านค้า'))
            : Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient( // Blue to Dark Purple gradient for TabBar
                        colors: [Color(0xFF0288D1), Color(0xFF4A00E0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: _tabs,
                      isScrollable: true,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      indicatorColor: Colors.white,
                      indicatorWeight: 3.0,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList(OrderStatus.pending),
                        _buildOrdersList(OrderStatus.processing),
                        _buildOrdersList(OrderStatus.shipped),
                        _buildOrdersList(OrderStatus.delivered),
                        _buildOrdersList(OrderStatus.cancelled),
                      ],
                    ),
                  ),
                ],
              );

    if (!widget.isEmbedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Lighter background color
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white, // White icon
          ),
          title: const Text(
            'รายการออเดอร์ของฉัน',
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white), // White text
          ),
          centerTitle: true,
        ),
        body: screenContent,
      );
    }

    return Container(
      color: const Color(0xFFF0F4F8), // Lighter background color
      child: screenContent,
    );
  }

  Widget _buildOrdersList(OrderStatus status) {
    if (_storeId == null) {
      return const Center(child: Text('ไม่สามารถโหลดข้อมูลร้านค้าได้'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('orders')
          .where('storeId', isEqualTo: _storeId)
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))); // Blue loading
        }
        if (snapshot.hasError) {
          return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'ไม่มีออเดอร์ "${status.name}"',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs.map((doc) => Order.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(order: order);
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm', 'th');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3, // Added elevation
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          ).then((value) {
            if (value == true) {
              // Handle refresh if needed
            }
          });
        },
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87), // Darker text
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16), // Grey arrow
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: Colors.grey[700]), // Darker grey icon
                  const SizedBox(width: 8),
                  Text('ผู้ซื้อ: ${order.buyerName}', style: TextStyle(fontSize: 14, color: Colors.grey[800])), // Darker text
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey[700]), // Darker grey icon
                   const SizedBox(width: 8),
                   Text('วันที่สั่ง: ${formatter.format(order.orderDate.toDate())}', style: TextStyle(fontSize: 14, color: Colors.grey[800])), // Darker text
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ยอดรวม: ฿${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A00E0)), // Dark Purple total
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
