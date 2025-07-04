// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:banbanshop/screens/profile.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // For File
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage

class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  const SellerAccountScreen({super.key, this.sellerProfile});

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  SellerProfile? _currentSellerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    setState(() {
      _isLoading = true;
    });

    final User? currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      try {
        // ดึงข้อมูลโปรไฟล์ผู้ขายจาก Supabase
        final Map<String, dynamic>? response = await Supabase.instance.client
            .from('sellers')
            .select()
            .eq('id', currentUser.id) // ใช้ id ของผู้ใช้ปัจจุบัน
            .maybeSingle(); // Use maybeSingle() to return null if no row found

        if (!mounted) return;

        if (response != null) {
          setState(() {
            _currentSellerProfile = SellerProfile.fromJson(response);
          });
        } else {
          // If no profile found, initialize with default values
          setState(() {
            _currentSellerProfile = SellerProfile(
              fullName: 'ชื่อ - นามสกุล',
              phoneNumber: '099 999 9999',
              idCardNumber: '',
              province: '',
              password: '',
              email: currentUser.email ?? '',
              profileImageUrl: null, // Default to null image
            );
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถดึงข้อมูลโปรไฟล์ได้: $e')),
          );
          setState(() {
            _currentSellerProfile = null; // Set to null on other errors
          });
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

  // ฟังก์ชันเลือกและอัปโหลดรูปภาพโปรไฟล์
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // ผู้ใช้ยกเลิกการเลือกรูปภาพ

    File imageFile = File(pickedFile.path);
    final User? currentUser = Supabase.instance.client.auth.currentUser;

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
      // 1. อัปโหลดรูปภาพไปยัง Supabase Storage
      // ตั้งชื่อไฟล์ให้ไม่ซ้ำกันและอยู่ในโฟลเดอร์ของผู้ใช้
      final String fileName = '${currentUser.id}/profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = fileName; // path คือ fileName ใน bucket นั้นๆ

      await Supabase.instance.client.storage
          .from('profile.pictures') // ชื่อ bucket ของคุณใน Supabase Storage
          .upload(
            path,
            imageFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true, // อัปเดตไฟล์เดิมถ้ามีอยู่แล้ว
              contentType: 'image/jpeg', // ระบุประเภทของไฟล์
              metadata: {
                'user_id': currentUser.id, // ส่ง User ID ของผู้ใช้ปัจจุบันไปกับ metadata
              },
            ),
          );

      // 2. รับ URL สาธารณะของรูปภาพ
      final String publicUrl = Supabase.instance.client.storage
          .from('profile.pictures') // ชื่อ bucket ของคุณ
          .getPublicUrl(path); // ใช้ path ที่อัปโหลดไป

      print('Public URL obtained: $publicUrl'); // Debug print

      if (publicUrl.isNotEmpty) {
        // 3. อัปเดต URL รูปภาพในตาราง sellers ของ Supabase
        await Supabase.instance.client
            .from('sellers')
            .update({'profile_image_url': publicUrl}) // แก้ไขตรงนี้ให้ตรงกับชื่อคอลัมน์ใน Supabase
            .eq('id', currentUser.id);

        // 4. อัปเดต UI
        if (!mounted) return;
        setState(() {
          _currentSellerProfile = _currentSellerProfile?.copyWith(profileImageUrl: publicUrl) ??
                                 SellerProfile(
                                   fullName: 'ชื่อ - นามสกุล',
                                   phoneNumber: '099 999 9999',
                                   idCardNumber: '',
                                   province: '',
                                   password: '',
                                   email: currentUser.email ?? '',
                                   profileImageUrl: publicUrl,
                                 );
          // Clear CachedNetworkImage's cache for the old image and new image
          CachedNetworkImage.evictFromCache(publicUrl); // Evict new URL
          if (_currentSellerProfile?.profileImageUrl != null) {
            CachedNetworkImage.evictFromCache(_currentSellerProfile!.profileImageUrl!); // Evict old URL if exists
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปโหลดรูปโปรไฟล์สำเร็จ!')),
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถรับ URL รูปภาพจาก Supabase ได้')),
          );
        }
      }
    } on StorageException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ (Storage): ${e.message}')),
        );
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
      await Supabase.instance.client.auth.signOut(); // ออกจากระบบด้วย Supabase
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากระบบแล้ว')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SellerLoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e')),
        );
      }
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

    // สร้าง Key ที่ไม่ซ้ำกันสำหรับ CircleAvatar เพื่อบังคับให้ rebuild
    // Key จะเปลี่ยนเมื่อ profileImageUrl เปลี่ยน ทำให้ CircleAvatar ถูกสร้างใหม่
    final Key profileImageKey = ValueKey(_currentSellerProfile?.profileImageUrl ?? 'default_profile_image');

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
                  onTap: _pickAndUploadImage, // เรียกใช้ฟังก์ชันเลือกรูปโปรไฟล์
                  child: CircleAvatar(
                    key: profileImageKey, // เพิ่ม Key ที่นี่
                    radius: 50,
                    backgroundColor: Colors.grey[300], // สีพื้นหลังของวงกลม
                    // ตรวจสอบว่ามี URL รูปโปรไฟล์และเป็น URL ที่ถูกต้องหรือไม่
                    child: (_currentSellerProfile?.profileImageUrl != null && _currentSellerProfile!.profileImageUrl!.startsWith('http'))
                        ? ClipOval( // ใช้ ClipOval เพื่อให้รูปภาพกลม
                            child: CachedNetworkImage(
                              imageUrl: _currentSellerProfile!.profileImageUrl!,
                              fit: BoxFit.cover,
                              width: 100, // ขนาดเท่ากับ radius * 2
                              height: 100, // ขนาดเท่ากับ radius * 2
                              placeholder: (context, url) => const CircularProgressIndicator(), // แสดง loading indicator ระหว่างโหลด
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.grey), // ถ้าโหลดไม่ได้ก็แสดง Icon default
                            ),
                          )
                        : const Icon( // ถ้าไม่มี URL รูปโปรไฟล์ ให้แสดง Icon default
                            Icons.person, // Icon ผู้ใช้เริ่มต้น
                            size: 60, // ขนาดของ Icon
                            color: Colors.grey, // สีของ Icon
                          ),
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
