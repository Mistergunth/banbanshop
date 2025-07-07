// lib/screens/seller/seller_account_screen.dart (ฉบับแก้ไข)

// ignore_for_file: use_build_context_synchronously

import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/reviews/store_reviews_screen.dart'; // <-- เพิ่ม Import ที่จำเป็น

class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  final VoidCallback? onRefresh;

  const SellerAccountScreen({
    super.key,
    this.sellerProfile,
    this.onRefresh,
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
          widget.onRefresh?.call();
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
    // AuthWrapper will handle navigation
  }

  void _navigateAndRefreshOnStoreCreation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreCreateScreen(
          onRefresh: widget.onRefresh,
        ),
      ),
    );
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
                // --- ส่วนที่แก้ไข: จัดกลุ่มปุ่มสำหรับผู้ขายที่มีร้านค้า ---
                if (seller.hasStore == true && seller.storeId != null)
                  Column(
                    children: [
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
                      const SizedBox(height: 15),
                      _buildActionButton(
                        text: 'เรตติ้งและรีวิว',
                        color: const Color(0xFFE2CCFB),
                        onTap: () {
                          // แก้ไข: นำทางไปยังหน้า Reviews
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreReviewsScreen(
                                storeId: seller.storeId!,
                                storeName: seller.shopName ?? 'ร้านค้าของคุณ',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  _buildActionButton(
                    text: 'สร้างร้านค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: _navigateAndRefreshOnStoreCreation,
                  ),
                // --- จบส่วนที่แก้ไข ---

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
              color: Colors.black.withOpacity(0.05),
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
