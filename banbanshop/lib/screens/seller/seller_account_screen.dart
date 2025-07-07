// lib/screens/seller/seller_account_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:banbanshop/main.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:banbanshop/screens/seller/store_profile.dart'; // Import StoreProfileScreen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // For File
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // Import Cloudinary SDK

class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  const SellerAccountScreen({super.key, this.sellerProfile});

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  SellerProfile? _currentSellerProfile;
  bool _isLoading = true;

  // Define your Cloudinary credentials here
  // ***** IMPORTANT: Replace YOUR_CLOUDINARY_CLOUD_NAME, YOUR_CLOUDINARY_API_KEY, YOUR_CLOUDINARY_API_SECRET with your actual values *****
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- Replace with your Cloud Name
    apiKey: '157343641351425', // <-- Required for Signed Uploads/Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- Required for Signed Uploads/Deletion
  );
  final String uploadPreset = 'flutter_unsigned_upload'; // <-- Replace with your Upload Preset name (e.g., 'flutter_unsigned_upload')

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
          // If seller profile doesn't exist, create a basic one.
          // This ensures _currentSellerProfile is not null,
          // allowing the UI to render and prompt for store creation.
          _currentSellerProfile = SellerProfile(
            fullName: 'ชื่อ - นามสกุล',
            phoneNumber: '099 999 9999',
            idCardNumber: '',
            province: '',
            password: '',
            email: currentUser.email ?? '',
            profileImageUrl: null,
            hasStore: false, // Default to no store
            storeId: null, // Default to no store ID
            shopName: null,
            shopAvatarImageUrl: null,
            shopPhoneNumber: null,
            shopLatitude: null,
            shopLongitude: null,
          );
          // Optionally, save this new profile to Firestore here if you want it persistent immediately
          // await FirebaseFirestore.instance.collection('sellers').doc(currentUser.uid).set(_currentSellerProfile!.toJson());
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

  // Function to pick and upload profile image (no cropping)
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // User cancelled image selection

    File imageFile = File(pickedFile.path); // Use the selected file directly
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
      _isLoading = true; // Show loading indicator
    });

    try {
      // 1. Upload image to Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'profile_pictures', // Folder name in Cloudinary (if desired)
          uploadPreset: uploadPreset, // Use the created Upload Preset
        ),
      );

      if (response.isSuccessful) {
        String? downloadUrl = response.secureUrl; // URL of the successfully uploaded image
        if (downloadUrl != null) {
          // 2. Update image URL in Firestore
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(currentUser.uid)
              .update({'profileImageUrl': downloadUrl});

          // 3. Update UI
          if (!mounted) return;
          setState(() {
            _currentSellerProfile = _currentSellerProfile?.copyWith(profileImageUrl: downloadUrl) ??
                SellerProfile( // Fallback if _currentSellerProfile was null initially
                  fullName: 'ชื่อ - นามสกุล',
                  phoneNumber: '099 999 9999',
                  idCardNumber: '',
                  province: '',
                  password: '',
                  email: currentUser.email ?? '',
                  profileImageUrl: downloadUrl,
                  hasStore: false, // Ensure default values are set
                  storeId: null,
                  shopName: null,
                  shopAvatarImageUrl: null,
                  shopPhoneNumber: null,
                  shopLatitude: null,
                  shopLongitude: null,
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
        _isLoading = false; // Hide loading indicator
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

    // Determine profile image
    ImageProvider<Object> profileImage;
    if (_currentSellerProfile != null && _currentSellerProfile!.profileImageUrl != null && _currentSellerProfile!.profileImageUrl!.startsWith('http')) {
      profileImage = NetworkImage(_currentSellerProfile!.profileImageUrl!);
    } else {
      profileImage = const AssetImage('assets/images/gunth.jpg'); // Your default image
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
                  onTap: _pickAndUploadImage, // Call profile image selection function
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImage,
                    // Show camera icon when no valid profile image
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
                // Conditionally render "สร้างร้านค้า" or "หน้าโปรไฟล์ร้านค้า"
                if (_currentSellerProfile?.hasStore == true && _currentSellerProfile?.storeId != null)
                  _buildActionButton(
                    text: 'หน้าโปรไฟล์ร้านค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StoreProfileScreen(
                            storeId: _currentSellerProfile!.storeId!,
                            isSellerView: true, // This is the seller's view of their own store
                          ),
                        ),
                      ).then((_) => _loadSellerProfile()); // Reload profile after returning from store profile
                    },
                  )
                else
                  _buildActionButton(
                    text: 'สร้างร้านค้า',
                    color: const Color(0xFFE2CCFB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StoreCreateScreen()),
                      ).then((_) => _loadSellerProfile()); // Reload profile after creating store
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
