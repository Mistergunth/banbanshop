// lib/screens/buyer/buyer_profile_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:banbanshop/screens/role_select.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Firestore
import 'package:banbanshop/screens/models/buyer_profile.dart'; // import BuyerProfile model
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';
import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
// ignore: unused_import
import 'package:banbanshop/main.dart'; // สำหรับ HomePage
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:image_picker/image_picker.dart'; // เพื่อนำทางไป HomePage หลัง Logout
import 'dart:io'; // สำหรับ File

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  User? _currentUser;
  BuyerProfile? _buyerProfile;
  bool _isLoading = true; // สถานะการโหลดข้อมูล

  // กำหนดค่า Cloudinary ของคุณที่นี่
  // ***** สำคัญ: ต้องแทนที่ค่า YOUR_CLOUDINARY_CLOUD_NAME, YOUR_CLOUDINARY_API_KEY, YOUR_CLOUDINARY_API_SECRET ด้วยค่าจริงของคุณ *****
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- แทนที่ด้วย Cloud Name ของคุณ
    apiKey: '157343641351425', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
  );
  final String uploadPreset = 'flutter_unsigned_upload'; // <-- แทนที่ด้วยชื่อ Upload Preset ที่คุณสร้าง (เช่น 'flutter_unsigned_upload')

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
          profileImageUrl: null, // ค่าเริ่มต้น
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

  // ฟังก์ชันเลือกและอัปโหลดรูปภาพโปรไฟล์สำหรับผู้ซื้อ
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // ผู้ใช้ยกเลิกการเลือกรูปภาพ

    File imageFile = File(pickedFile.path);
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนอัปโหลดรูปภาพ')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true; // แสดง loading indicator
    });

    try {
      // 1. อัปโหลดรูปภาพไปยัง Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'buyer_profile_pictures', // โฟลเดอร์สำหรับรูปโปรไฟล์ผู้ซื้อ
          uploadPreset: uploadPreset, // ใช้ Upload Preset ที่สร้างไว้
        ),
      );

      if (response.isSuccessful) {
        String? downloadUrl = response.secureUrl; // URL ของรูปภาพที่อัปโหลดสำเร็จ
        if (downloadUrl != null) {
          // 2. อัปเดต URL รูปภาพใน Firestore
          await FirebaseFirestore.instance
              .collection('buyers')
              .doc(currentUser.uid)
              .update({'profileImageUrl': downloadUrl});

          // 3. อัปเดต UI
          if (!mounted) return;
          setState(() {
            _buyerProfile = _buyerProfile?.copyWith(profileImageUrl: downloadUrl) ??
                            BuyerProfile(
                              uid: currentUser.uid,
                              email: currentUser.email ?? '',
                              fullName: currentUser.displayName,
                              phoneNumber: currentUser.phoneNumber,
                              shippingAddress: null,
                              profileImageUrl: downloadUrl,
                            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ!')),
            );
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่สามารถรับ URL รูปภาพจาก Cloudinary ได้')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // ซ่อน loading indicator
      });
    }
  }


  // ฟังก์ชันสำหรับจัดการการออกจากระบบ
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
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
    // กำหนดรูปโปรไฟล์
    ImageProvider<Object> profileImage;
    // ตรวจสอบว่ามี _buyerProfile และ profileImageUrl ไม่เป็น null และเป็น URL ที่ถูกต้อง
    if (_buyerProfile != null && _buyerProfile!.profileImageUrl != null && _buyerProfile!.profileImageUrl!.startsWith('http')) {
      profileImage = NetworkImage(_buyerProfile!.profileImageUrl!);
    } else {
      // ใช้รูปภาพเริ่มต้นจาก assets หรือไอคอน
      profileImage = const AssetImage('assets/images/default_avatar.png'); // สมมติว่ามีไฟล์นี้
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage, // เรียกใช้ฟังก์ชันเลือกรูปโปรไฟล์
          child: CircleAvatar(
            radius: 50,
            backgroundImage: profileImage,
            // แสดงไอคอนกล้องเมื่อไม่มีรูปโปรไฟล์ที่ถูกต้อง
            child: (_buyerProfile?.profileImageUrl == null || !_buyerProfile!.profileImageUrl!.startsWith('http'))
                ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                : null,
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
