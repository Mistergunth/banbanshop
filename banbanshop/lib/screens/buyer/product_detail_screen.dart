// lib/screens/buyer/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/product_model.dart';
import 'package:banbanshop/screens/models/cart_model.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isLoading = false;

  Store? _store;
  bool _isStoreLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStoreStatus();
  }

  Future<void> _fetchStoreStatus() async {
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.product.storeId)
          .get();
      if (storeDoc.exists && mounted) {
        setState(() {
          _store = Store.fromFirestore(storeDoc);
          _isStoreLoading = false;
        });
      } else {
         if (mounted) {
          setState(() {
            _isStoreLoading = false;
          });
         }
      }
    } catch (e) {
      print("Error fetching store status: $e");
      if (mounted) {
        setState(() {
          _isStoreLoading = false;
        });
      }
    }
  }


  bool get isOutOfStock {
    return widget.product.stock <= 0 && widget.product.stock != -1;
  }

  bool get isStoreOpen {
    if (_store == null) return false;
    return _store!.isOpen;
  }

  void _incrementQuantity() {
    if (widget.product.stock != -1 && _quantity >= widget.product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเพิ่มเกินจำนวนสต็อกที่มี (${widget.product.stock} ชิ้น)')),
      );
      return;
    }
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  Future<void> _addToCart() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อเพิ่มสินค้าลงตะกร้า')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cartRef = FirebaseFirestore.instance
        .collection('buyers')
        .doc(currentUser.uid)
        .collection('cart')
        .doc(widget.product.id);

    try {
      final doc = await cartRef.get();

      if (doc.exists) {
        await cartRef.update({
          'quantity': FieldValue.increment(_quantity),
        });
      } else {
        final newCartItem = CartItem(
          productId: widget.product.id,
          storeId: widget.product.storeId,
          name: widget.product.name,
          imageUrl: widget.product.imageUrl,
          price: widget.product.price,
          quantity: _quantity,
          addedAt: Timestamp.now(),
        );
        await cartRef.set(newCartItem.toFirestore());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่ม ${widget.product.name} จำนวน $_quantity ชิ้น ลงตะกร้าแล้ว')),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canAddToCart = !isOutOfStock && isStoreOpen && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              color: Colors.grey[200],
              child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        return progress == null ? child : const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey));
                      },
                    )
                  : const Center(child: Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '฿${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, color: Color(0xFF9C6ADE), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isOutOfStock 
                      ? 'สินค้าหมด' 
                      : (widget.product.stock == -1 
                          ? 'มีสินค้า' 
                          : 'มีสินค้าทั้งหมด: ${widget.product.stock} ชิ้น'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isOutOfStock ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 16),
                  const Text(
                    'รายละเอียด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty ? widget.product.description : 'ไม่มีคำอธิบายสำหรับสินค้านี้',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isStoreLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
              )
            else if (!isStoreOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.door_back_door_outlined, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ขณะนี้ร้านค้าปิดทำการ',
                        style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: !canAddToCart ? null : _decrementQuantity,
                      iconSize: 30,
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: !canAddToCart ? null : _incrementQuantity,
                      iconSize: 30,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: canAddToCart ? _addToCart : null,
                  icon: (isOutOfStock || !isStoreOpen || _isLoading)
                      ? const SizedBox.shrink()
                      : const Icon(Icons.add_shopping_cart),
                  label: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(isOutOfStock ? 'สินค้าหมด' : (isStoreOpen ? 'เพิ่มลงตะกร้า' : 'ร้านปิด')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAddToCart ? const Color(0xFF66BB6A) : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.kanit().fontFamily ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
