// lib/screens/seller/product_management_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/product_model.dart';
import 'package:banbanshop/screens/seller/add_edit_product_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  final String storeId;

  const ProductManagementScreen({super.key, required this.storeId});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  
  void _navigateToAddEditScreen({Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProductScreen(
          storeId: widget.storeId,
          product: product, // Pass the product for editing, or null for adding
        ),
      ),
    );
  }

  Future<void> _toggleAvailability(Product product) async {
    final productRef = FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.storeId)
        .collection('products')
        .doc(product.id);

    try {
      await productRef.update({'isAvailable': !product.isAvailable});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปลี่ยนสถานะ ${product.name} สำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสินค้า'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'เพิ่มสินค้าใหม่',
            onPressed: () => _navigateToAddEditScreen(),
            color: Colors.white, // White icon
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('products')
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
                  const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('ยังไม่มีสินค้าในร้านของคุณ', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddEditScreen(),
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มสินค้าชิ้นแรก'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1), // Blue button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      shadowColor: const Color(0xFF0288D1).withOpacity(0.3),
                    ),
                  )
                ],
              ),
            );
          }

          final products = snapshot.data!.docs.map((doc) => Product.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3, // Added elevation
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF0288D1), // Blue loading
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey), // Grey icon
                          ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('฿${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF4A00E0), fontWeight: FontWeight.w600)), // Dark Purple price
                      Text(
                        product.stock == -1 ? 'สต็อก: ไม่จำกัด' : 'สต็อก: ${product.stock} ชิ้น',
                        style: TextStyle(color: Colors.grey[700]), // Darker text
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: product.isAvailable,
                    onChanged: (value) => _toggleAvailability(product),
                    activeColor: const Color(0xFF0288D1), // Blue active color
                  ),
                  onTap: () => _navigateToAddEditScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
