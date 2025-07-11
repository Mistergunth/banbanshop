// lib/screens/seller/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    setState(() => _isLoading = true);

    final db = FirebaseFirestore.instance;
    final orderRef = db.collection('stores').doc(widget.order.storeId).collection('orders').doc(widget.order.id);

    try {
      // --- [KEY CHANGE] Use a transaction to update stock and order status together ---
      if (newStatus == OrderStatus.shipped) {
        // This is the critical part: deduct stock when confirming payment
        await db.runTransaction((transaction) async {
          // 1. Loop through each item in the order
          for (final item in widget.order.items) {
            final productRef = db
                .collection('stores')
                .doc(widget.order.storeId)
                .collection('products')
                .doc(item.productId);
            
            final productDoc = await transaction.get(productRef);

            if (!productDoc.exists) {
              throw Exception("Product with ID ${item.productId} not found!");
            }
            
            final currentStock = productDoc.data()!['stock'] as int;
            // Only deduct stock if it's not unlimited (-1)
            if (currentStock != -1) {
              final newStock = currentStock - item.quantity;
              transaction.update(productRef, {'stock': newStock < 0 ? 0 : newStock}); // Prevent negative stock
            }
          }

          // 2. After updating all product stocks, update the order status
          transaction.update(orderRef, {'status': newStatus.toString().split('.').last});
        });
      } else {
        // For other status updates (like cancelling), just update the status
        await orderRef.update({'status': newStatus.toString().split('.').last});
      }

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

  void _showSlipDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.transparent),
          ),
        ),
      ),
    );
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
            if (order.paymentSlipUrl != null && order.paymentSlipUrl!.isNotEmpty)
              _buildPaymentSlipSection(order.paymentSlipUrl!),

            const SizedBox(height: 24),
            _buildStatusManagementSection(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentSlipSection(String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'หลักฐานการชำระเงิน',
          children: [
            GestureDetector(
              onTap: () => _showSlipDialog(imageUrl),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('ไม่สามารถแสดงรูปภาพได้')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusManagementSection() {
    if (widget.order.status == OrderStatus.pending) {
      return _buildActionButton(
        text: 'ยกเลิกออเดอร์',
        onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
        color: Colors.red,
      );
    }
    
    if (widget.order.status == OrderStatus.processing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            text: 'ยืนยันการชำระเงิน (เตรียมจัดส่ง)',
            onPressed: () => _updateOrderStatus(OrderStatus.shipped),
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            text: 'ปฏิเสธ (ยกเลิกออเดอร์)',
            onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
            color: Colors.red.withOpacity(0.8),
          ),
        ],
      );
    }
    
    // --- [NEW] Add button for when order is shipped ---
    if (widget.order.status == OrderStatus.shipped) {
       return _buildActionButton(
        text: 'สินค้าจัดส่งถึงแล้ว',
        onPressed: () => _updateOrderStatus(OrderStatus.delivered),
        color: Colors.blue,
      );
    }

    return Card(
      child: ListTile(
        title: const Text('สถานะปัจจุบัน', style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          widget.order.status.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String text, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(text),
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
