// lib/screens/buyer/buyer_profile_screen.dart (ฉบับแก้ไข)

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';
import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/buyer/favorites_screen.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  User? _currentUser;
  BuyerProfile? _buyerProfile;
  bool _isLoading = true;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = true;
        });
        if (_currentUser != null) {
          _fetchBuyerProfile();
        } else {
          setState(() {
            _isLoading = false;
            _buyerProfile = null;
          });
        }
      }
    });

    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchBuyerProfile();
    } else {
      _isLoading = false;
    }
  }

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
        if (mounted) {
          setState(() {
            _buyerProfile = BuyerProfile.fromFirestore(doc);
          });
        }
      } else {
        final newProfile = BuyerProfile(
          uid: _currentUser!.uid,
          email: _currentUser!.email ?? '',
          fullName: _currentUser!.displayName,
          phoneNumber: _currentUser!.phoneNumber,
          shippingAddress: null,
          profileImageUrl: null,
        );
        await FirebaseFirestore.instance.collection('buyers').doc(_currentUser!.uid).set(newProfile.toFirestore());
        if (mounted) {
          setState(() {
            _buyerProfile = newProfile;
          });
        }
      }
    } catch (e) {
      print("Error fetching buyer profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลโปรไฟล์: $e')),
        );
        setState(() {
          _buyerProfile = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // แก้ไข: ใส่โค้ดที่ทำงานได้จริงกลับเข้าไป
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    User? currentUser = _currentUser;

    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'buyer_profile_pictures',
          uploadPreset: uploadPreset,
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        String downloadUrl = response.secureUrl!;
        await FirebaseFirestore.instance
            .collection('buyers')
            .doc(currentUser.uid)
            .update({'profileImageUrl': downloadUrl});

        if (mounted) {
          setState(() {
            _buyerProfile = _buyerProfile?.copyWith(profileImageUrl: downloadUrl);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตรูปโปรไฟล์สำเร็จ!')),
          );
        }
      } else {
        throw Exception(response.error ?? 'Cloudinary upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // AuthWrapper will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser != null && _buyerProfile != null) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildProfileOptionButton(
                      icon: Icons.location_on_outlined,
                      text: 'ที่อยู่จัดส่ง',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ฟีเจอร์นี้ยังไม่พร้อมใช้งาน')),
                        );
                      },
                    ),
                    _buildProfileOptionButton(
                      icon: Icons.favorite_border,
                      text: 'ร้านค้าโปรด',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                        );
                      },
                    ),
                     _buildProfileOptionButton(
                      icon: Icons.rate_review_outlined,
                      text: 'รีวิวของฉัน',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ฟีเจอร์นี้ยังไม่พร้อมใช้งาน')),
                        );
                      },
                    ),
                    _buildProfileOptionButton(
                      icon: Icons.edit_outlined,
                      text: 'แก้ไขโปรไฟล์',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ฟีเจอร์นี้ยังไม่พร้อมใช้งาน')),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildProfileOptionButton(
                      icon: Icons.logout,
                      text: 'ออกจากระบบ',
                      onTap: _logout,
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'เข้าสู่ระบบหรือสมัครสมาชิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'เพื่อดูประวัติการสั่งซื้อและจัดการโปรไฟล์ของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerRegisterScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProfileHeader() {
    ImageProvider<Object> profileImage;
    if (_buyerProfile?.profileImageUrl != null && _buyerProfile!.profileImageUrl!.startsWith('http')) {
      profileImage = NetworkImage(_buyerProfile!.profileImageUrl!);
    } else {
      profileImage = const AssetImage('assets/images/default_avatar.png');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F0F7),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: profileImage,
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
      ),
    );
  }

  Widget _buildProfileOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
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
                if (!isLogout)
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
