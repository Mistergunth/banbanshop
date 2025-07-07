// lib/screens/seller/seller_account_screen.dart (ฉบับแก้ไข)

// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';

class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  final VoidCallback? onRefresh; // <-- 1. ทำให้เป็น Optional (nullable)

  const SellerAccountScreen({
    super.key,
    this.sellerProfile,
    this.onRefresh, // <-- 2. เอา required ออก
  });

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'profile_pictures',
          uploadPreset: uploadPreset,
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        String downloadUrl = response.secureUrl!;
        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(currentUser.uid)
            .update({'profileImageUrl': downloadUrl});

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตโปรไฟล์สำเร็จ!')),
          );
          widget.onRefresh?.call(); // <-- 3. เรียกใช้ฟังก์ชัน onRefresh ถ้ามี
        }
      } else {
        throw Exception(response.error ?? 'Unknown Cloudinary error');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')),
        );
      }
    }
  }

  void _logoutSeller() async {
    await FirebaseAuth.instance.signOut();
    // ไม่ต้องทำอะไรต่อ AuthWrapper จะจัดการเอง
  }

  void _navigateAndRefreshOnStoreCreation() async {
    // แก้ไข: ลบตัวแปร result ที่ไม่ได้ใช้งานออก
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreCreateScreen(
          // ส่งฟังก์ชัน onRefresh ต่อไป
          onRefresh: widget.onRefresh,
        ),
      ),
    );

    // ไม่จำเป็นต้องทำอะไรที่นี่แล้ว เพราะ StoreCreateScreen จะเป็นคนเรียก onRefresh เอง
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sellerProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final seller = widget.sellerProfile!;

    ImageProvider<Object> profileImage;
    if (seller.profileImageUrl != null && seller.profileImageUrl!.startsWith('http')) {
      profileImage = NetworkImage(seller.profileImageUrl!);
    } else {
      profileImage = const AssetImage('assets/images/gunth.jpg');
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
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage,
                    child: (seller.profileImageUrl == null || !seller.profileImageUrl!.startsWith('http'))
                        ? const Icon(Icons.camera_alt, size: 30, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  seller.fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                Text(
                  seller.phoneNumber,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                Text(
                  seller.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (seller.hasStore == true && seller.storeId != null)
                  _buildActionButton(
                    text: 'หน้าโปรไฟล์ร้านค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreProfileScreen(
                            storeId: seller.storeId!,
                            isSellerView: true,
                          ),
                        ),
                      );
                    },
                  )
                else
                  _buildActionButton(
                    text: 'สร้างร้านค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: _navigateAndRefreshOnStoreCreation,
                  ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'ดูออเดอร์',
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    // Navigate to orders screen
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'จัดการสินค้า',
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    // Navigate to product management screen
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
