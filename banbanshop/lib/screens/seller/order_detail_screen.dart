// lib/screens/seller/order_detail_screen.dart

import 'package:flutter/material.dart';
// [KEY FIX] Hide the conflicting 'Order' class from the firestore package
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderStatus _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  Future<void> _updateOrderStatus() async {
    if (_currentStatus == widget.order.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สถานะไม่มีการเปลี่ยนแปลง')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Since we hid 'Order', we can now use FirebaseFirestore directly without issues.
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.order.storeId)
          .collection('orders')
          .doc(widget.order.id)
          .update({'status': _currentStatus.toString().split('.').last});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตสถานะออเดอร์สำเร็จ!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Pop with a result to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm', 'th');

    return Scaffold(
      appBar: AppBar(
        title: Text('ออเดอร์ #${order.id.substring(0, 8)}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: 'ข้อมูลผู้ซื้อ',
              children: [
                _buildInfoRow(Icons.person_outline, 'ชื่อ:', order.buyerName),
                _buildInfoRow(Icons.phone_outlined, 'เบอร์โทร:', order.buyerPhoneNumber),
                _buildInfoRow(Icons.home_outlined, 'ที่อยู่:', order.shippingAddress, isAddress: true),
              ],
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'รายการสินค้า',
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl ?? 'https://placehold.co/60x60/EFEFEF/AAAAAA?text=No+Image',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('จำนวน: ${item.quantity}'),
                          ],
                        ),
                      ),
                      Text('฿${(item.price * item.quantity).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'สรุปยอด',
              children: [
                _buildInfoRow(null, 'ยอดรวม:', '฿${order.totalAmount.toStringAsFixed(2)}'),
                _buildInfoRow(null, 'วันที่สั่งซื้อ:', formatter.format(order.orderDate.toDate())),
              ],
            ),
            const SizedBox(height: 24),
            const Text('จัดการสถานะออเดอร์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<OrderStatus>(
                  value: _currentStatus,
                  isExpanded: true,
                  items: OrderStatus.values.map((OrderStatus status) {
                    return DropdownMenuItem<OrderStatus>(
                      value: status,
                      child: Text(status.name),
                    );
                  }).toList(),
                  onChanged: (OrderStatus? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _currentStatus = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateOrderStatus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('อัปเดตสถานะ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData? icon, String label, String value, {bool isAddress = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
          ],
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }
}
