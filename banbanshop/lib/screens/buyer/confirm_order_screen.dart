// lib/screens/buyer/confirm_order_screen.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final String storeId;
  final String ownerUid;

  Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.storeId,
    required this.ownerUid,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'ไม่มีชื่อสินค้า',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      storeId: data['storeId'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
    );
  }
}

class Address {
  final String id;
  final String name;
  final String fullAddress;
  final String phone;

  Address({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.phone,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      name: data['name'] ?? '',
      fullAddress: data['address'] ?? '',
      phone: data['phone'] ?? '',
    );
  }
}


class ConfirmOrderScreen extends StatefulWidget {
  final String productId;

  const ConfirmOrderScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ConfirmOrderScreen> createState() => _ConfirmOrderScreenState();
}

enum ShippingMethod { delivery, pickup }
enum PaymentMethod { transfer, cod }

class _ConfirmOrderScreenState extends State<ConfirmOrderScreen> {
  Product? _product;
  List<Address> _addresses = [];
  Address? _selectedAddress;
  ShippingMethod _shippingMethod = ShippingMethod.delivery;
  PaymentMethod _paymentMethod = PaymentMethod.transfer;

  bool _isLoading = true;
  bool _isPlacingOrder = false;
  final double _shippingFee = 10.00; 

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error", "Please log in to continue.");
      return;
    }

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('Product not found.');
      }
      final product = Product.fromFirestore(productDoc);

      final addressSnapshot = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .collection('addresses')
          .get();
      final addresses = addressSnapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();

      setState(() {
        _product = product;
        _addresses = addresses;
        if (_addresses.isNotEmpty) {
          _selectedAddress = _addresses.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
      _showErrorDialog("Error", "Failed to load order details: $e");
    }
  }

  Future<void> _placeOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _product == null) {
        _showErrorDialog("Error", "Cannot place order. User or product data is missing.");
        return;
    }

    if (_selectedAddress == null) {
        _showErrorDialog("Validation Error", "Please select a shipping address.");
        return;
    }

    setState(() => _isPlacingOrder = true);

    try {
        final orderData = {
            'buyerId': user.uid,
            'buyerName': user.displayName ?? 'N/A',
            'storeId': _product!.storeId,
            'orderStatus': 'pending_payment',
            'paymentMethod': _paymentMethod == PaymentMethod.transfer ? 'transfer' : 'cod',
            'shippingAddress': {
                'name': _selectedAddress!.name,
                'address': _selectedAddress!.fullAddress,
                'phone': _selectedAddress!.phone,
            },
            'items': [
                {
                    'productId': _product!.id,
                    'productName': _product!.name,
                    'imageUrl': _product!.imageUrl,
                    'quantity': 1,
                    'price': _product!.price,
                }
            ],
            'subtotal': _product!.price,
            'shippingFee': _shippingFee,
            'totalAmount': _product!.price + _shippingFee,
            'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('stores')
            .doc(_product!.storeId)
            .collection('orders')
            .add(orderData);

        await FirebaseFirestore.instance
            .collection('buyers')
            .doc(user.uid)
            .collection('orders')
            .add(orderData);

        _showSuccessDialog();

    } catch (e) {
        print("Error placing order: $e");
        _showErrorDialog("Order Failed", "An error occurred while placing your order. Please try again.");
    } finally {
        setState(() => _isPlacingOrder = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text('Order Placed!'),
            content: const Text('Your order has been successfully placed.'),
            actions: [
                TextButton(
                    onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                ),
            ],
        ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                ),
            ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text('ยืนยันคำสั่งซื้อ'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
          : _product == null
              ? const Center(child: Text('ไม่สามารถโหลดข้อมูลสินค้าได้'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('วิธีจัดส่ง'),
                            _buildShippingMethodSelector(),
                            const SizedBox(height: 24),

                            _buildSectionHeader('ที่อยู่ในการจัดส่ง'),
                            _buildAddressSelector(),
                            const SizedBox(height: 24),

                            _buildSectionHeader('รายการสินค้า'),
                            _buildProductItem(_product!),
                            const SizedBox(height: 24),

                            _buildSectionHeader('วิธีชำระเงิน'),
                            _buildPaymentMethodSelector(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    _buildOrderSummary(),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Darker text
      ),
    );
  }

  Widget _buildShippingMethodSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2, // Added elevation
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'จัดส่ง',
                icon: Icons.local_shipping,
                isSelected: _shippingMethod == ShippingMethod.delivery,
                onSelected: (selected) {
                  setState(() => _shippingMethod = ShippingMethod.delivery);
                },
                selectedColor: const Color(0xFF0288D1), // Blue selected color
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: 'รับที่ร้าน',
                icon: Icons.store,
                isSelected: _shippingMethod == ShippingMethod.pickup,
                onSelected: (selected) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('การรับที่ร้านยังไม่พร้อมใช้งาน')));
                },
                selectedColor: const Color(0xFF4A00E0), // Dark Purple selected color
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressSelector() {
    if (_addresses.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: const Text('ไม่มีที่อยู่', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)), // Red text
          subtitle: const Text('กรุณาเพิ่มที่อยู่ของคุณในหน้าโปรไฟล์'),
          trailing: const Icon(Icons.info_outline, color: Colors.redAccent), // Red info icon
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2, // Added elevation
      child: ListTile(
        leading: const Icon(Icons.location_on, color: Color(0xFF0288D1)), // Blue icon
        title: Text(_selectedAddress?.name ?? 'เลือกที่อยู่', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
        subtitle: Text(_selectedAddress?.fullAddress ?? 'กรุณาเลือกที่อยู่สำหรับจัดส่ง', style: TextStyle(color: Colors.grey[700])), // Darker subtitle
        trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Grey arrow
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ฟังก์ชันเลือกที่อยู่ยังไม่พร้อมใช้งาน')));
        },
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2, // Added elevation
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null ? child : Center(child: CircularProgressIndicator(color: const Color(0xFF0288D1))); // Blue loading
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87), // Darker text
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('จำนวน: 1', style: TextStyle(color: Colors.grey[700])), // Darker text
                ],
              ),
            ),
            Text(
              '฿${NumberFormat("#,##0.00").format(product.price)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A00E0)), // Dark Purple price
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2, // Added elevation
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'โอนเงิน',
                icon: Icons.account_balance_wallet,
                isSelected: _paymentMethod == PaymentMethod.transfer,
                onSelected: (selected) {
                  setState(() => _paymentMethod = PaymentMethod.transfer);
                },
                selectedColor: const Color(0xFF0288D1), // Blue selected color
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: 'เก็บปลายทาง',
                icon: Icons.delivery_dining,
                isSelected: _paymentMethod == PaymentMethod.cod,
                onSelected: (selected) {
                  setState(() => _paymentMethod = PaymentMethod.cod);
                },
                selectedColor: const Color(0xFF4A00E0), // Dark Purple selected color
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color selectedColor, // Added selectedColor parameter
  }) {
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, color: isSelected ? Colors.white : Colors.black54),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: selectedColor, // Use the passed selectedColor
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = _product?.price ?? 0.0;
    final total = subtotal + _shippingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ราคาสินค้า', style: TextStyle(color: Colors.black87)), // Darker text
              Text('฿${NumberFormat("#,##0.00").format(subtotal)}', style: const TextStyle(color: Colors.black87)), // Darker text
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ค่าจัดส่ง', style: TextStyle(color: Colors.black87)), // Darker text
              Text('฿${NumberFormat("#,##0.00").format(_shippingFee)}', style: const TextStyle(color: Colors.black87)), // Darker text
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('สรุปยอดชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)), // Darker text
              Text(
                '฿${NumberFormat("#,##0.00").format(total)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4A00E0)), // Dark Purple total
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isPlacingOrder || _selectedAddress == null) ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1), // Blue confirm button
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Text(
                      'ยืนยันคำสั่งซื้อ (${NumberFormat("#,##0.00").format(total)})',
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
