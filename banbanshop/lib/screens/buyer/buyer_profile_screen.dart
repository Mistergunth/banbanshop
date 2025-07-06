// lib/screens/buyer/buyer_profile_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Firestore
import 'package:banbanshop/screens/models/buyer_profile.dart'; // import BuyerProfile model
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';
import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
import 'package:banbanshop/main.dart'; // เพื่อนำทางไป HomePage หลัง Logout

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  User? _currentUser;
  BuyerProfile? _buyerProfile;
  bool _isLoading = true; // สถานะการโหลดข้อมูล

  @override
  void initState() {
    super.initState();
    // Listener เพื่อฟังการเปลี่ยนแปลงสถานะการล็อกอิน
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) { // ตรวจสอบว่า widget ยังคงอยู่ก่อน setState
        setState(() {
          _currentUser = user;
          _isLoading = true; // ตั้งค่าให้โหลดใหม่เมื่อสถานะเปลี่ยน
        });
        if (_currentUser != null) {
          _fetchBuyerProfile(); // ถ้ามีผู้ใช้ล็อกอินอยู่ ให้ดึงข้อมูลโปรไฟล์
        } else {
          // ถ้าไม่มีผู้ใช้ล็อกอินแล้ว ให้หยุดโหลด
          setState(() {
            _isLoading = false;
            _buyerProfile = null; // เคลียร์ข้อมูลโปรไฟล์เก่า
          });
        }
      }
    });

    // ตรวจสอบสถานะเริ่มต้นเมื่อ Widget ถูกสร้างขึ้น
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchBuyerProfile();
    } else {
      _isLoading = false; // ถ้าไม่มีผู้ใช้ตั้งแต่แรก ไม่ต้องโหลด
    }
  }

  // ฟังก์ชันดึงข้อมูลโปรไฟล์ผู้ซื้อจาก Firestore
  Future<void> _fetchBuyerProfile() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _buyerProfile = BuyerProfile.fromFirestore(doc);
        });
      } else {
        // หากไม่มีข้อมูลใน Firestore (อาจจะเพิ่งสมัครและยังไม่ได้สร้างโปรไฟล์)
        // สร้างโปรไฟล์เริ่มต้นจากข้อมูล FirebaseAuth และบันทึกลง Firestore
        final newProfile = BuyerProfile(
          uid: _currentUser!.uid,
          email: _currentUser!.email ?? '',
          fullName: _currentUser!.displayName,
          phoneNumber: _currentUser!.phoneNumber,
          shippingAddress: null, // ค่าเริ่มต้น
        );
        await FirebaseFirestore.instance.collection('buyers').doc(_currentUser!.uid).set(newProfile.toFirestore());
        setState(() {
          _buyerProfile = newProfile;
        });
      }
    } catch (e) {
      print("Error fetching buyer profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลโปรไฟล์: $e')),
      );
      setState(() {
        _buyerProfile = null; // ในกรณีที่ error ให้เป็น null
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ฟังก์ชันสำหรับจัดการการออกจากระบบ
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // ไม่ต้อง setState ตรงนี้ เพราะ authStateChanges listener จะจัดการให้
      // และจะนำทางกลับไปหน้า HomePage โดยอัตโนมัติ
      // (ถ้า HomePage ใน main.dart มี logic ตรวจสอบการล็อกอินอยู่แล้ว)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()), // กลับไปหน้าแรกของแอป (HomePage ใน main.dart)
          (route) => false,
        );
      }
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('โปรไฟล์ผู้ซื้อ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ถ้าล็อกอินแล้ว (_currentUser ไม่เป็น null) และโหลดข้อมูลโปรไฟล์เสร็จแล้ว
    if (_currentUser != null) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ส่วนแสดงรูปโปรไฟล์และชื่อ
              _buildProfileHeader(),
              const SizedBox(height: 20),
              // ปุ่มต่างๆ สำหรับผู้ใช้ที่ล็อกอินแล้ว
              _buildProfileOptionButton(
                icon: Icons.location_on,
                text: 'ที่อยู่จัดส่ง',
                onTap: () {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไปยังหน้าจัดการที่อยู่จัดส่ง')),
                  );
                },
              ),
              _buildProfileOptionButton(
                icon: Icons.favorite,
                text: 'รายการโปรด',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไปยังหน้าแสดงรายการโปรด')),
                  );
                },
              ),
              _buildProfileOptionButton(
                icon: Icons.edit,
                text: 'แก้ไขโปรไฟล์',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไปยังหน้าแก้ไขโปรไฟล์ผู้ซื้อ')),
                  );
                },
              ),
              _buildProfileOptionButton(
                icon: Icons.logout,
                text: 'ออกจากระบบ',
                onTap: _logout,
                isLogout: true,
              ),
            ],
          ),
        ),
      );
    } else {
      // ถ้ายังไม่ได้ล็อกอิน ให้แสดง UI เดิมของคุณ
      return Scaffold(
        backgroundColor: Colors.grey[50], // สีพื้นหลังอ่อนๆ
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ไอคอนเพื่อเพิ่มความสวยงาม
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),

                // ข้อความเชิญชวน
                const Text(
                  'เข้าสู่ระบบหรือสมัครสมาชิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เพื่อดูประวัติการสั่งซื้อและจัดการโปรไฟล์ของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // ปุ่มเข้าสู่ระบบ
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen()));
                    print('Navigate to Login Screen');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // ปุ่มสมัครสมาชิก
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerRegisterScreen()));
                    print('Navigate to Register Screen');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'สมัครสมาชิก',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ส่วนแสดง Header ของโปรไฟล์ (รูปภาพ, ชื่อ, อีเมล, เบอร์โทร)
  Widget _buildProfileHeader() {
    return Column(
      children: [
        // รูปโปรไฟล์ (ใช้ไอคอนเริ่มต้น)
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: 60,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _buyerProfile?.fullName ?? _currentUser?.displayName ?? _currentUser?.email ?? 'ผู้ซื้อ',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          _buyerProfile?.email ?? _currentUser?.email ?? '',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        if (_buyerProfile?.phoneNumber != null && _buyerProfile!.phoneNumber!.isNotEmpty)
          Text(
            _buyerProfile!.phoneNumber!,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
      ],
    );
  }

  // Widget สำหรับสร้างปุ่มตัวเลือกในหน้าโปรไฟล์
  Widget _buildProfileOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false, // เพื่อให้ปุ่ม Logout มีสีแดง
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: isLogout ? Colors.red : const Color(0xFF9B7DD9)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isLogout ? Colors.red : Colors.black87,
                  ),
                ),
              ),
              if (!isLogout) // ไม่แสดงลูกศรสำหรับปุ่ม Logout
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
