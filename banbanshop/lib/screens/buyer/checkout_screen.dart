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
  
  app_order.DeliveryMethod _selectedDeliveryMethod = app_order.DeliveryMethod.delivery;
  app_order.PaymentMethod _selectedPaymentMethod = app_order.PaymentMethod.transfer;
  
  final double _shippingFee = 10.00;

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
            _selectedAddress = fetchedAddresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => fetchedAddresses.first,
            );
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
    if (_selectedDeliveryMethod == app_order.DeliveryMethod.delivery && _selectedAddress == null) {
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
    final double currentShippingFee = _selectedDeliveryMethod == app_order.DeliveryMethod.delivery ? _shippingFee : 0;
    final double totalAmount = subtotal + currentShippingFee;

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
        buyerName: _selectedAddress?.contactName ?? user.displayName ?? 'N/A',
        buyerPhoneNumber: _selectedAddress?.phoneNumber ?? 'N/A',
        shippingAddress: _selectedDeliveryMethod == app_order.DeliveryMethod.delivery 
            ? _selectedAddress!.addressLine 
            : 'รับสินค้าเองที่ร้าน',
        shippingLocation: _selectedDeliveryMethod == app_order.DeliveryMethod.delivery
            ? _selectedAddress!.location
            : null,
        items: orderItems,
        totalAmount: totalAmount,
        orderDate: Timestamp.now(),
        status: _selectedPaymentMethod == app_order.PaymentMethod.cod 
            ? app_order.OrderStatus.processing 
            : app_order.OrderStatus.pending,   
        deliveryMethod: _selectedDeliveryMethod.toString().split('.').last,
        paymentMethod: _selectedPaymentMethod.toString().split('.').last,
      );

      final orderRef = await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .collection('orders')
          .add(newOrder.toFirestore());

      if (mounted) {
        if (_selectedPaymentMethod == app_order.PaymentMethod.transfer) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สร้างคำสั่งซื้อสำเร็จ! กรุณาชำระเงิน')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentScreen(orderId: orderRef.id, storeId: storeId),
            ),
          );
        } else {
          final cartCollection = FirebaseFirestore.instance.collection('buyers').doc(user.uid).collection('cart');
          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var item in widget.cartItems) {
            batch.delete(cartCollection.doc(item.productId));
          }
          await batch.commit();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สั่งซื้อสำเร็จ! เตรียมรอรับสินค้าและชำระเงินปลายทาง')),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างคำสั่งซื้อ: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _showAddressSelectionDialog() {
    if (_addresses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณยังไม่มีที่อยู่จัดส่ง กรุณาเพิ่มที่อยู่ก่อน')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เลือกที่อยู่จัดส่ง',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    final bool isSelected = _selectedAddress?.id == address.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: isSelected ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected ? const BorderSide(color: Color(0xFF9C6ADE), width: 2) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isSelected ? const Color(0xFF9C6ADE) : Colors.grey,
                        ),
                        title: Text(address.contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(address.addressLine),
                        onTap: () {
                          setState(() {
                            _selectedAddress = address;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double subtotal = widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    final double currentShippingFee = _selectedDeliveryMethod == app_order.DeliveryMethod.delivery ? _shippingFee : 0;
    final double totalAmount = subtotal + currentShippingFee;

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
                  _buildSectionTitle('วิธีจัดส่ง'),
                  _buildDeliveryMethodSelector(),
                  const SizedBox(height: 24),

                  if (_selectedDeliveryMethod == app_order.DeliveryMethod.delivery) ...[
                    _buildSectionTitle('ที่อยู่ในการจัดส่ง'),
                    _buildAddressSection(),
                    const SizedBox(height: 24),
                  ],

                  _buildSectionTitle('รายการสินค้า'),
                  _buildItemsList(),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('วิธีชำระเงิน'),
                  _buildPaymentMethodSelector(),
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
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDeliveryMethodSelector() {
    return SegmentedButton<app_order.DeliveryMethod>(
      segments: const <ButtonSegment<app_order.DeliveryMethod>>[
        ButtonSegment<app_order.DeliveryMethod>(
            value: app_order.DeliveryMethod.delivery,
            label: Text('จัดส่ง'),
            icon: Icon(Icons.local_shipping_outlined)),
        ButtonSegment<app_order.DeliveryMethod>(
            value: app_order.DeliveryMethod.pickup,
            label: Text('รับที่ร้าน'),
            icon: Icon(Icons.storefront_outlined)),
      ],
      selected: {_selectedDeliveryMethod},
      onSelectionChanged: (Set<app_order.DeliveryMethod> newSelection) {
        setState(() {
          _selectedDeliveryMethod = newSelection.first;
        });
      },
    );
  }

   Widget _buildPaymentMethodSelector() {
    return SegmentedButton<app_order.PaymentMethod>(
      segments: const <ButtonSegment<app_order.PaymentMethod>>[
        ButtonSegment<app_order.PaymentMethod>(
            value: app_order.PaymentMethod.transfer,
            label: Text('โอนเงิน'),
            icon: Icon(Icons.qr_code)),
        ButtonSegment<app_order.PaymentMethod>(
            value: app_order.PaymentMethod.cod,
            label: Text('เก็บปลายทาง'),
            icon: Icon(Icons.money_outlined)),
      ],
      selected: {_selectedPaymentMethod},
      onSelectionChanged: (Set<app_order.PaymentMethod> newSelection) {
        setState(() {
          _selectedPaymentMethod = newSelection.first;
        });
      },
    );
  }

  Widget _buildAddressSection() {
    if (_addresses.isEmpty) {
      return Card(child: ListTile(title: Text('กรุณาเพิ่มที่อยู่ในโปรไฟล์ของคุณ'), onTap: (){/* TODO: Navigate to add address screen */},));
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined, color: Color(0xFF9C6ADE)),
        title: Text(_selectedAddress?.contactName ?? 'เลือกที่อยู่', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_selectedAddress?.addressLine ?? 'ยังไม่ได้เลือกที่อยู่'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: _showAddressSelectionDialog,
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
            _buildPriceRow('ค่าจัดส่ง', _selectedDeliveryMethod == app_order.DeliveryMethod.delivery ? _shippingFee : 0),
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
