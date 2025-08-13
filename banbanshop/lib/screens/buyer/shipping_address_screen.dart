// lib/screens/buyer/shipping_address_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/address_model.dart';
import 'package:banbanshop/screens/buyer/add_edit_address_screen.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _navigateToAddEditScreen([Address? address]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    );
    // Refresh addresses after returning from AddEditAddressScreen
    setState(() {}); 
  }

  Future<void> _deleteAddress(String addressId) async {
     if (user == null) return;
     bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบที่อยู่นี้?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red))),
          ],
        ),
     );
     
     if (confirm == true) {
        try {
          await FirebaseFirestore.instance
              .collection('buyers')
              .doc(user!.uid)
              .collection('addresses')
              .doc(addressId)
              .delete();
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ลบที่อยู่สำเร็จ')),
             );
          }
        } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการลบ: $e')),
             );
          }
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ที่อยู่จัดส่ง'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF21CBF3)], // Blue to Dark Purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบเพื่อจัดการที่อยู่')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ที่อยู่จัดส่ง'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buyers')
            .doc(user!.uid)
            .collection('addresses')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))); // Blue loading
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('ยังไม่มีที่อยู่ที่บันทึกไว้', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final addresses = snapshot.data!.docs
              .map((doc) => Address.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA), // Light blue background for label
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              address.label,
                              style: const TextStyle(
                                color: Color(0xFF0288D1), // Blue text for label
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF0288D1)), // Blue edit icon
                                onPressed: () => _navigateToAddEditScreen(address),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red), // Red delete icon
                                onPressed: () => _deleteAddress(address.id),
                              ),
                            ],
                          )
                        ],
                      ),
                      const Divider(height: 20),
                      Text(address.contactName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)), // Darker text
                      Text(address.phoneNumber, style: TextStyle(color: Colors.grey[700])), // Darker text
                      const SizedBox(height: 4),
                      Text(address.addressLine, style: TextStyle(color: Colors.grey[700])), // Darker text
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEditScreen(),
        backgroundColor: const Color(0xFF4A00E0), // Dark Purple FAB
        child: const Icon(Icons.add, color: Colors.white), // White icon
      ),
    );
  }
}
