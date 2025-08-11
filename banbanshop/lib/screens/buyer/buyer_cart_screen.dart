// lib/screens/buyer/buyer_cart_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/cart_model.dart';
import 'package:banbanshop/screens/buyer/checkout_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerCartScreen extends StatefulWidget {
  const BuyerCartScreen({super.key});

  @override
  State<BuyerCartScreen> createState() => _BuyerCartScreenState();
}

class _BuyerCartScreenState extends State<BuyerCartScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<CartItem>> _getCartItemsStream() {
    if (_currentUser == null) {
      return Stream.value([]); // Return empty stream if not logged in
    }
    return FirebaseFirestore.instance
        .collection('buyers')
        .doc(_currentUser.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItem.fromFirestore(doc))
            .toList());
  }

  void _updateQuantity(String productId, int change) {
    if (_currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('buyers')
        .doc(_currentUser.uid)
        .collection('cart')
        .doc(productId);

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw Exception("Product does not exist in cart!");
      }
      final newQuantity = (snapshot.data()!['quantity'] as int) + change;
      if (newQuantity > 0) {
        transaction.update(docRef, {'quantity': newQuantity});
      } else {
        // If quantity is 0 or less, remove the item
        transaction.delete(docRef);
      }
    });
  }

  void _removeItem(String productId) {
     if (_currentUser == null) return;
    FirebaseFirestore.instance
        .collection('buyers')
        .doc(_currentUser.uid)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: const Center(
          child: Text('กรุณาเข้าสู่ระบบเพื่อดูตะกร้าสินค้าของคุณ'),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<CartItem>>(
        stream: _getCartItemsStream(),
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
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ตะกร้าของคุณว่างเปล่า', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          double totalPrice = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildCartItemCard(item);
                  },
                ),
              ),
              _buildSummary(totalPrice, cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3, // Added elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Increased padding
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                image: item.imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
               child: item.imageUrl == null
                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 15), // Increased spacing
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)), // Larger, darker text
                  const SizedBox(height: 6),
                  Text('฿${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF4A00E0), fontSize: 15, fontWeight: FontWeight.bold)), // Dark Purple price
                ],
              ),
            ),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _updateQuantity(item.productId, -1)), // Red icon
                Text('${item.quantity}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)), // Larger, darker text
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _updateQuantity(item.productId, 1)), // Green icon
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeItem(item.productId)), // Red icon
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(double totalPrice, List<CartItem> cartItems) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
              const Text('ยอดรวม:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
              Text(
                '฿${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A00E0)), // Dark Purple total price
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (cartItems.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(cartItems: cartItems),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถดำเนินการได้เนื่องจากตะกร้าว่างเปล่า')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0288D1), // Blue checkout button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: Text('ไปที่หน้าชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: GoogleFonts.kanit().fontFamily)),
            ),
          ),
        ],
      ),
    );
  }
}
