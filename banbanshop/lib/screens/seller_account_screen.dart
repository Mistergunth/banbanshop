// ignore_for_file: deprecated_member_use

import 'package:banbanshop/screens/seller_login_screen.dart';
import 'package:flutter/material.dart';

class SellerAccountScreen extends StatelessWidget {
  const SellerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บัญชีผู้ขาย', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F0F7), // Light blue background for app bar
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0F7), // Light blue background
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/profile_placeholder.png'), // Replace with your image asset
                    // Or use NetworkImage if loading from URL:
                    // backgroundImage: NetworkImage('https://via.placeholder.com/150'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'กันตพงศ์ ศรีลิว', // Replace with actual user name
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '099 999 9999', // Replace with actual phone number
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildActionButton(
                    context,
                    text: 'สร้างร้านค้า',
                    color: const Color(0xFFE2CCFB), // Purple from image
                    onTap: () {
                      // Handle "สร้างร้านค้า" action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ไปยังหน้าสร้างร้านค้า')),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    context,
                    text: 'เปิด/ปิดร้าน',
                    color: const Color(0xFFD6F6E0), // Light green from image
                    onTap: () {
                      // Handle "เปิด/ปิดร้าน" action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เปิด/ปิดร้านค้า')),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    context,
                    text: 'ดูออเดอร์',
                    color: const Color(0xFFE2CCFB),
                    onTap: () {
                      // Handle "ดูออเดอร์" action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ดูรายการออเดอร์')),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    context,
                    text: 'จัดการสินค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: () {
                      // Handle "จัดการสินค้า" action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('จัดการสินค้า')),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'สินค้า',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'บัญชี',
          ),
        ],
        currentIndex: 2, // Highlight the "บัญชี" icon
        selectedItemColor: Color(0xFF9B7DD9), // Matching your theme color
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Handle navigation for bottom navigation bar
          // For example:
          // if (index == 0) {
          //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          // } else if (index == 1) {
          //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProductScreen()));
          // }
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle logout logic here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบ...')),
        );
        // Example: Navigate back to login screen or home screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SellerLoginScreen()), // หรือหน้าหลักของแอป
          (route) => false, // Remove all previous routes
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.logout, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward, color: Colors.red),
          ],
        ),
      ),
    );
  }
}