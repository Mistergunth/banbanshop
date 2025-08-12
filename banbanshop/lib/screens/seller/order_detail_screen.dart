// lib/screens/seller/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:banbanshop/screens/seller/seller_live_tracking_screen.dart';
import 'package:banbanshop/screens/seller/seller_pickup_tracking_screen.dart';


class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  late OrderStatus _currentOrderStatus;

  @override
  void initState() {
    super.initState();
    _currentOrderStatus = widget.order.status;
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_isLoading || _currentOrderStatus == newStatus) return;

    setState(() => _isLoading = true);

    final db = FirebaseFirestore.instance;
    final orderRef = db.collection('stores').doc(widget.order.storeId).collection('orders').doc(widget.order.id);

    try {
      bool shouldDeductStock = (newStatus == OrderStatus.shipped && widget.order.paymentMethod == 'transfer') ||
                               (newStatus == OrderStatus.shipped && widget.order.paymentMethod == 'cod');

      if (shouldDeductStock) {
        await db.runTransaction((transaction) async {
          for (final item in widget.order.items) {
            final productRef = db.collection('stores').doc(widget.order.storeId).collection('products').doc(item.productId);
            final productDoc = await transaction.get(productRef);

            if (!productDoc.exists) throw Exception("Product with ID ${item.productId} not found!");
            
            final currentStock = productDoc.data()!['stock'] as int;
            if (currentStock != -1) {
              final newStock = currentStock - item.quantity;
              transaction.update(productRef, {'stock': newStock < 0 ? 0 : newStock});
            }
          }
          transaction.update(orderRef, {'status': newStatus.toString().split('.').last});
        });
      } else {
        await orderRef.update({'status': newStatus.toString().split('.').last});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตสถานะออเดอร์สำเร็จ!'), backgroundColor: Colors.green),
        );
        
        setState(() {
          _currentOrderStatus = newStatus;
        });

        if (newStatus == OrderStatus.delivered || newStatus == OrderStatus.cancelled) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
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
    final order = widget.order.copyWith(status: _currentOrderStatus); 
    final DateFormat formatter = DateFormat('dd MMMM yyyy, HH:mm', 'th');

    return Scaffold(
      appBar: AppBar(
        title: Text('ออเดอร์ #${order.id.substring(0, 8)}'),
        centerTitle: true,
        flexibleSpace: Container( // Added flexibleSpace for gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
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
                if (order.deliveryMethod == 'delivery')
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
                          width: 60, height: 60, fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))), // Blue loading
                          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)), // Grey error icon
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
                            Text('จำนวน: ${item.quantity}', style: TextStyle(color: Colors.grey[700])), // Darker text
                          ],
                        ),
                      ),
                      Text('฿${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A00E0))), // Dark Purple price
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'สรุปยอดและวิธีจัดส่ง',
              children: [
                _buildInfoRow(Icons.delivery_dining_outlined, 'วิธีจัดส่ง:', order.deliveryMethod == 'pickup' ? 'รับที่ร้าน' : 'จัดส่ง'),
                _buildInfoRow(Icons.payment_outlined, 'วิธีชำระเงิน:', order.paymentMethod == 'cod' ? 'เก็บเงินปลายทาง' : 'โอนเงิน'),
                const Divider(height: 20),
                _buildInfoRow(null, 'ยอดรวม:', '฿${order.totalAmount.toStringAsFixed(2)}', valueColor: const Color(0xFF4A00E0)), // Dark Purple total
                _buildInfoRow(null, 'วันที่สั่งซื้อ:', formatter.format(order.orderDate.toDate())),
              ],
            ),
            if (order.paymentSlipUrl != null && order.paymentSlipUrl!.isNotEmpty)
              _buildPaymentSlipSection(order.paymentSlipUrl!),

            const SizedBox(height: 24),
            _buildStatusManagementSection(order),
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
                    imageUrl, height: 200, fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))), // Blue loading
                    errorBuilder: (context, error, stackTrace) => const Center(child: Text('ไม่สามารถแสดงรูปภาพได้', style: TextStyle(color: Colors.red))), // Red error text
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusManagementSection(Order currentOrder) {
    if (currentOrder.status == OrderStatus.pending) {
      return _buildActionButton(
        text: 'ยกเลิกออเดอร์',
        onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
        color: Colors.red, // Red for cancel
      );
    }
    
    if (currentOrder.status == OrderStatus.processing) {
      bool isCOD = currentOrder.paymentMethod == 'cod';
      String buttonText = currentOrder.deliveryMethod == 'pickup'
          ? 'ยืนยัน (พร้อมให้ลูกค้ารับ)'
          : (isCOD ? 'ยืนยันออเดอร์ (เตรียมจัดส่ง)' : 'ยืนยันการชำระเงิน (เตรียมจัดส่ง)');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            text: buttonText,
            onPressed: () => _updateOrderStatus(OrderStatus.shipped),
            color: const Color(0xFF0288D1), // Blue for confirmation/shipping
          ),
          if (!isCOD && currentOrder.paymentSlipUrl != null) ...[
            const SizedBox(height: 10),
            _buildActionButton(
              text: 'ปฏิเสธ (ยกเลิกออเดอร์)',
              onPressed: () => _updateOrderStatus(OrderStatus.cancelled),
              color: Colors.red.withOpacity(0.8), // Red for rejection
            ),
          ],
        ],
      );
    }
    
    if (currentOrder.status == OrderStatus.shipped) {
       return Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           if (currentOrder.deliveryMethod == 'delivery')
             _buildActionButton(
               text: 'ติดตามการจัดส่ง (GPS)',
               onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => SellerLiveTrackingScreen(order: currentOrder),
                   ),
                 );
               },
               color: const Color(0xFF0288D1), // Blue for tracking
             )
           else
             _buildActionButton(
               text: 'ติดตามลูกค้าที่มารับสินค้า',
               onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => SellerPickupTrackingScreen(order: currentOrder),
                   ),
                 );
               },
               color: const Color(0xFF4A00E0), // Dark Purple for pickup tracking
             ),
           const SizedBox(height: 10),
           _buildActionButton(
             text: 'ลูกค้ารับสินค้า/จัดส่งถึงแล้ว',
             onPressed: () => _updateOrderStatus(OrderStatus.delivered),
             color: const Color(0xFFFFD700), // Yellow for delivered (tertiary color)
             textColor: Colors.black87, // Dark text for yellow button
           ),
         ],
       );
    }

    return Card(
      elevation: 2, // Added elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: ListTile(
        title: const Text('สถานะปัจจุบัน', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
        trailing: Text(
          currentOrder.status.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getStatusColor(currentOrder.status)), // Dynamic color for status
        ),
      ),
    );
  }

  Widget _buildActionButton({required String text, required VoidCallback onPressed, required Color color, Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor, // Use dynamic textColor
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), // Rounded corners
          elevation: 3, // Added elevation
          shadowColor: color.withOpacity(0.3), // Shadow matching button color
        ),
        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // Larger, bolder text
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
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData? icon, String label, String value, {bool isAddress = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey[600], size: 20), // Darker grey icon
            const SizedBox(width: 12),
          ],
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)), // Darker text
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? Colors.grey[800]))), // Dynamic value color
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return const Color(0xFF0288D1); // Blue for processing
      case OrderStatus.shipped:
        return const Color(0xFF4A00E0); // Dark Purple for shipped
      case OrderStatus.delivered:
        return const Color(0xFFFFD700); // Yellow for delivered
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}
