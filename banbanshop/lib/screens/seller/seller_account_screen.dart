import 'package:banbanshop/screens/profile.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart'; 
import 'package:flutter/material.dart';


class SellerAccountScreen extends StatelessWidget {
  final SellerProfile? sellerProfile; 
  const SellerAccountScreen({super.key, this.sellerProfile}); 

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0F7), 
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/gunth.jpg'), 
                ),
                const SizedBox(height: 10),
                Text(
                  sellerProfile?.fullName ?? 'ชื่อ - นามสกุล', 
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  sellerProfile?.phoneNumber ?? '099 999 9999', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                 Text(
                  sellerProfile?.email ?? 'email@example.com', 
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
                  text: 'สร้างร้านค้า', 
                  color: const Color(0xFFE2CCFB), 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้าสร้างร้านค้า')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'เปิด/ปิดร้าน', 
                  color: const Color(0xFFD6F6E0), 
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เปิด/ปิดร้านค้า')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'ดูออเดอร์', 
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('เปลี่ยนไปหน้าดูออเดอร์')),
                    );
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'จัดการสินค้า', 
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
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
    );
  }

  Widget _buildActionButton({
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบ...')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SellerLoginScreen()), 
          (route) => false, 
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
              // ignore: deprecated_member_use
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
