// lib/screens/buyer/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/cart_model.dart';
import 'package:banbanshop/screens/models/address_model.dart';
import 'package:banbanshop/screens/models/order_model.dart' as app_order;
import 'package:banbanshop/screens/models/order_item_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:banbanshop/screens/buyer/payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  List<Address> _addresses = [];
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  final double _shippingFee = 10.00; // Example shipping fee

  @override
  void initState() {
    super.initState();
    _fetchUserAddresses();
  }

  Future<void> _fetchUserAddresses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .collection('addresses')
          .get();

      final fetchedAddresses = snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
      
      if (mounted) {
        setState(() {
          _addresses = fetchedAddresses;
          if (fetchedAddresses.isNotEmpty) {
            _selectedAddress = fetchedAddresses.firstWhere((a) => a.isDefault, orElse: () => fetchedAddresses.first);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถโหลดที่อยู่ได้: $e')),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่อยู่สำหรับจัดส่ง')),
      );
      return;
    }
    if(widget.cartItems.isEmpty){
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ตะกร้าสินค้าของคุณว่างเปล่า')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final user = FirebaseAuth.instance.currentUser!;
    final storeId = widget.cartItems.first.storeId; 
    final double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    final double totalAmount = subtotal + _shippingFee;

    try {
      final List<OrderItem> orderItems = widget.cartItems.map((cartItem) {
        return OrderItem(
          productId: cartItem.productId,
          productName: cartItem.name,
          price: cartItem.price,
          quantity: cartItem.quantity,
          imageUrl: cartItem.imageUrl,
        );
      }).toList();

      final newOrder = app_order.Order(
        id: '', 
        storeId: storeId,
        buyerId: user.uid,
        buyerName: _selectedAddress!.contactName,
        buyerPhoneNumber: _selectedAddress!.phoneNumber,
        shippingAddress: _selectedAddress!.addressLine,
        items: orderItems,
        totalAmount: totalAmount,
        orderDate: Timestamp.now(),
        status: app_order.OrderStatus.pending,
      );

      final orderRef = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .add(newOrder.toFirestore());

      // --- [BUG FIX] The cart clearing logic has been REMOVED from this function. ---
      // The cart will now only be cleared after a successful payment confirmation.
      /*
      final cartCollection = FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .collection('cart');
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var item in widget.cartItems) {
        batch.delete(cartCollection.doc(item.productId));
      }
      await batch.commit();
      */

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างคำสั่งซื้อสำเร็จ! กรุณาชำระเงิน')),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              orderId: orderRef.id, 
              storeId: storeId
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างคำสั่งซื้อ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    final double totalAmount = subtotal + _shippingFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันคำสั่งซื้อ'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('ที่อยู่ในการจัดส่ง'),
                  _buildAddressSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('รายการสินค้า'),
                  _buildItemsList(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('สรุปยอดชำระเงิน'),
                  _buildPriceSummary(subtotal, totalAmount),
                ],
              ),
            ),
      bottomNavigationBar: _buildConfirmButton(totalAmount),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAddressSection() {
    if (_addresses.isEmpty) {
      return const Text('กรุณาเพิ่มที่อยู่ในโปรไฟล์ของคุณ');
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined, color: Color(0xFF9C6ADE)),
        title: Text(_selectedAddress?.contactName ?? 'เลือกที่อยู่', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_selectedAddress?.addressLine ?? 'ยังไม่ได้เลือกที่อยู่'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // TODO: Implement address selection dialog
        },
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.cartItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = widget.cartItems[index];
        return ListTile(
          leading: Image.network(item.imageUrl ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200])),
          title: Text(item.name),
          subtitle: Text('จำนวน: ${item.quantity}'),
          trailing: Text('฿${(item.price * item.quantity).toStringAsFixed(2)}'),
        );
      },
    );
  }

  Widget _buildPriceSummary(double subtotal, double totalAmount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPriceRow('ราคาสินค้า', subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('ค่าจัดส่ง', _shippingFee),
            const Divider(height: 24),
            _buildPriceRow('ยอดรวมสุทธิ', totalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text('฿${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
  
  Widget _buildConfirmButton(double totalAmount) {
     return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66BB6A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.kanit().fontFamily ),
          ),
          child: _isPlacingOrder
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : Text('ยืนยันคำสั่งซื้อ (฿${totalAmount.toStringAsFixed(2)})'),
        ),
      ),
    );
  }
}
