// ignore_for_file: use_build_context_synchronously

import 'package:banbanshop/main.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // สำหรับ File
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // Import Cloudinary SDK
// import 'package:image_cropper/image_cropper.dart'; // Removed image_cropper import

class SellerAccountScreen extends StatefulWidget { 
  final SellerProfile? sellerProfile; 
  const SellerAccountScreen({super.key, this.sellerProfile}); 

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  SellerProfile? _currentSellerProfile;
  bool _isLoading = true;

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
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    setState(() {
      _isLoading = true;
    });

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return;

        if (sellerDoc.exists) {
          setState(() {
            _currentSellerProfile = SellerProfile.fromJson(sellerDoc.data() as Map<String, dynamic>);
          });
        } else {
          setState(() {
            _currentSellerProfile = null; 
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถดึงข้อมูลโปรไฟล์ได้: $e')),
          );
        }
      }
    } else {
      setState(() {
        _currentSellerProfile = null;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  // ฟังก์ชันเลือกและอัปโหลดรูปภาพโปรไฟล์ (ไม่มีการครอปแล้ว)
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // ผู้ใช้ยกเลิกการเลือกรูปภาพ

    File imageFile = File(pickedFile.path); // ใช้ไฟล์ที่เลือกโดยตรง
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
          folder: 'profile_pictures', // ชื่อโฟลเดอร์ใน Cloudinary (ถ้าต้องการ)
          uploadPreset: uploadPreset, // ใช้ Upload Preset ที่สร้างไว้
        ),
      );

      if (response.isSuccessful) {
        String? downloadUrl = response.secureUrl; // URL ของรูปภาพที่อัปโหลดสำเร็จ
        if (downloadUrl != null) {
          // 2. อัปเดต URL รูปภาพใน Firestore
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(currentUser.uid)
              .update({'profileImageUrl': downloadUrl});

          // 3. อัปเดต UI
          if (!mounted) return;
          setState(() {
            _currentSellerProfile = _currentSellerProfile?.copyWith(profileImageUrl: downloadUrl) ??
                                    SellerProfile( 
                                      fullName: 'ชื่อ - นามสกุล',
                                      phoneNumber: '099 999 9999',
                                      idCardNumber: '',
                                      province: '',
                                      password: '',
                                      email: currentUser.email ?? '',
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

  void _logoutSeller() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากระบบแล้ว')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()), 
        (route) => false, 
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // กำหนดรูปโปรไฟล์
    ImageProvider<Object> profileImage;
    // ตรวจสอบว่ามี _currentSellerProfile และ profileImageUrl ไม่เป็น null และเป็น URL ที่ถูกต้อง
    if (_currentSellerProfile != null && _currentSellerProfile!.profileImageUrl != null && _currentSellerProfile!.profileImageUrl!.startsWith('http')) {
      profileImage = NetworkImage(_currentSellerProfile!.profileImageUrl!);
    } else {
      profileImage = const AssetImage('assets/images/gunth.jpg'); // รูปภาพเริ่มต้นของคุณ
    }

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
                GestureDetector( 
                  onTap: _pickAndUploadImage, // เรียกใช้ฟังก์ชันเลือกรูปโปรไฟล์ (ไม่มีการครอปแล้ว)
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage, 
                    // แสดงไอคอนกล้องเมื่อไม่มีรูปโปรไฟล์ที่ถูกต้อง
                    child: (_currentSellerProfile?.profileImageUrl == null || !_currentSellerProfile!.profileImageUrl!.startsWith('http'))
                        ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70) 
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentSellerProfile?.fullName ?? 'ชื่อ - นามสกุล', 
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _currentSellerProfile?.phoneNumber ?? '099 999 9999', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                 Text(
                  _currentSellerProfile?.email ?? 'email@example.com', 
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
                    Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const StoreCreateScreen())); // เปลี่ยนไปยังหน้าสร้างร้านค้า
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้าสร้างร้านค้า')),
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
      onTap: _logoutSeller, 
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
// Extension SellerProfileCopyWith ควรอยู่ใน profile.dart เท่านั้น
// extension SellerProfileCopyWith on SellerProfile {
//   SellerProfile copyWith({
//     String? fullName,
//     String? phoneNumber,
//     String? idCardNumber,
//     String? province,
//     String? password,
//     String? email,
//     String? profileImageUrl,
//   }) {
//     return SellerProfile(
//       fullName: fullName ?? this.fullName,
//       phoneNumber: phoneNumber ?? this.phoneNumber,
//       idCardNumber: idCardNumber ?? this.idCardNumber,
//       province: province ?? this.province,
//       password: password ?? this.password,
//       email: email ?? this.email,
//       profileImageUrl: profileImageUrl ?? this.profileImageUrl,
//     );
//   }
// }