// ignore_for_file: use_build_context_synchronously

import 'package:banbanshop/screens/profile.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // สำหรับ File

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
        final response = await Supabase.instance.client
            .from('sellers')
            .select()
            .eq('id', currentUser.id) // ใช้ id ของผู้ใช้ปัจจุบัน
            .single(); // คาดหวังผลลัพธ์เดียว

        if (!mounted) return;

        // ignore: unnecessary_null_comparison
        if (response != null) {
          setState(() {
            // ignore: unnecessary_cast
            _currentSellerProfile = SellerProfile.fromJson(response as Map<String, dynamic>);
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

      final response = await Supabase.instance.client.storage
          .from('profile.pictures')
          .upload(
            path,
            imageFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true, // อัปเดตไฟล์เดิมถ้ามีอยู่แล้ว
              contentType: 'image/jpeg', // ระบุประเภทของไฟล์
              // ***** สำคัญมาก: แนบ metadata ที่มี user_id *****
              metadata: {
                'user_id': currentUser.id, // ส่ง User ID ของผู้ใช้ปัจจุบันไปกับ metadata
              },
            ),
          );

      // ตรวจสอบว่า response ไม่ใช่ null และไม่มี error (Supabase upload returns a path string on success)
      // ignore: unnecessary_null_comparison
      if (response != null && response.isNotEmpty) {
        // 2. รับ URL สาธารณะของรูปภาพ
        final String publicUrl = Supabase.instance.client.storage
            .from('profile.pictures') // ชื่อ bucket ของคุณ
            .getPublicUrl(path); // ใช้ path ที่อัปโหลดไป

        if (publicUrl.isNotEmpty) {
          // 3. อัปเดต URL รูปภาพในตาราง sellers ของ Supabase
          await Supabase.instance.client
              .from('sellers')
              .update({'profileImageUrl': publicUrl})
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ')),
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
                  onTap: _pickAndUploadImage, // เรียกใช้ฟังก์ชันเลือกรูปโปรไฟล์
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
