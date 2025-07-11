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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'เพิ่มสินค้าใหม่',
            onPressed: () => _navigateToAddEditScreen(),
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
            return const Center(child: CircularProgressIndicator());
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
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image_not_supported, size: 60),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported),
                          ),
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('฿${product.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
                      Text(
                        product.stock == -1 ? 'สต็อก: ไม่จำกัด' : 'สต็อก: ${product.stock} ชิ้น',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: product.isAvailable,
                    onChanged: (value) => _toggleAvailability(product),
                    activeColor: Colors.green,
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
