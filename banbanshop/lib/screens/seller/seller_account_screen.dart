import 'package:banbanshop/screens/profile.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:banbanshop/widgets/bottom_navbar_widget.dart';
import 'package:banbanshop/screens/feed_page.dart'; // Import feed_page.dart
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'dart:io'; // สำหรับ File
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // Import Cloudinary SDK
import 'package:image_cropper/image_cropper.dart'; // Import image_cropper
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore


// Import หน้าจออื่นๆ ของผู้ขายที่จะใช้ใน Bottom Navbar
// ควรสร้างไฟล์เหล่านี้ใน lib/screens/seller/
// import 'package:banbanshop/screens/seller/seller_orders_screen.dart';    // TODO: สร้างไฟล์นี้
// import 'package:banbanshop/screens/seller/seller_create_store_screen.dart'; // TODO: สร้างไฟล์นี้
// import 'package:banbanshop/screens/seller/seller_product_management_screen.dart'; // TODO: สร้างไฟล์นี้


class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  const SellerAccountScreen({super.key, this.sellerProfile}); 

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  int _selectedIndex = 0; // กำหนดเริ่มต้นที่ Index 0 (หน้าแรก/ฟีดโพสต์) สำหรับผู้ขาย

  // List ของ Widgets ที่จะแสดงผลตาม Bottom Navbar
  // จะเก็บเฉพาะเนื้อหา (body) ของแต่ละหน้าจอ ไม่รวม Scaffold และ AppBar
  late List<Widget> _pages; 

  // กำหนดค่า Cloudinary ของคุณที่นี่
  // ***** สำคัญ: ต้องแทนที่ค่า YOUR_CLOUDINARY_CLOUD_NAME, YOUR_CLOUDINARY_API_KEY, YOUR_CLOUDINARY_API_SECRET ด้วยค่าจริงของคุณ *****
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- แทนที่ด้วย Cloud Name ของคุณ
    apiKey: '157343641351425', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
  );
  final String uploadPreset = 'ml_default'; // <-- ใช้ 'ml_default' หรือชื่อ Upload Preset ที่คุณสร้าง

  SellerProfile? _currentSellerProfile; // เพิ่ม state เพื่อเก็บโปรไฟล์ปัจจุบัน

  @override
  void initState() {
    super.initState();
    _loadSellerProfile(); // โหลดโปรไฟล์เมื่อ Widget ถูกสร้าง
    // กำหนดลิสต์ของหน้าที่ Bottom Navbar จะสลับไป
    // Index 0: หน้าแรก/ฟีดโพสต์ (ใช้ FeedPage)
    // Index 1: หน้ารายการออเดอร์ของผู้ขาย
    // Index 2: หน้าโปรไฟล์ผู้ขาย
    _pages = [
      // Index 0: หน้าแรก/ฟีดโพสต์ (ใช้ FeedPage)
      // เมื่อผู้ขายเข้ามา ควรแสดงฟีดโพสต์ทั่วไป อาจจะดึงข้อมูลจากจังหวัดที่ผู้ขายอยู่
      // สำหรับตอนนี้ เราจะส่งค่าเริ่มต้นไปก่อน
      FeedPage(
        selectedProvince: widget.sellerProfile?.province ?? 'ทั้งหมด', // ใช้จังหวัดผู้ขาย หรือ 'ทั้งหมด'
        selectedCategory: 'ทั้งหมด', // สำหรับหน้าแรก ให้แสดงทุกหมวดหมู่
        sellerProfile: widget.sellerProfile, // ส่ง sellerProfile ไปยัง FeedPage
      ),
      // Index 1: หน้ารายการออเดอร์ของผู้ขาย
      _buildSellerOrdersContent(),
      // Index 2: หน้าโปรไฟล์ผู้ขาย (เนื้อหาเดิมของ SellerAccountScreen)
      _buildSellerProfileContent(),
    ];
  }

  // โหลดข้อมูลโปรไฟล์ผู้ขายจาก Firestore
  Future<void> _loadSellerProfile() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(currentUser.uid)
            .get();

        if (!mounted) return; // ตรวจสอบว่า widget ยัง mounted อยู่

        if (sellerDoc.exists) {
          setState(() {
            _currentSellerProfile = SellerProfile.fromJson(sellerDoc.data() as Map<String, dynamic>);
          });
        } else {
          // ถ้าไม่มีข้อมูลใน Firestore ให้ใช้ข้อมูลจาก widget.sellerProfile (ถ้ามี)
          setState(() {
            _currentSellerProfile = widget.sellerProfile;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ไม่สามารถดึงข้อมูลโปรไฟล์ได้: $e')),
          );
        }
        setState(() {
          _currentSellerProfile = widget.sellerProfile; // ใช้ข้อมูลที่ส่งมาหากดึงจาก Firestore ไม่ได้
        });
      }
    } else {
      setState(() {
        _currentSellerProfile = widget.sellerProfile; // ใช้ข้อมูลที่ส่งมาหากยังไม่ได้ล็อกอิน
      });
    }
  }

  // เมธอดสำหรับจัดการการเลือก Bottom Navbar Item
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // สร้าง Widget แยกสำหรับเนื้อหาของหน้ารายการออเดอร์ของผู้ขาย (Index 1)
  Widget _buildSellerOrdersContent() {
    return const Center(
      child: Text('นี่คือหน้าสำหรับดูรายการออเดอร์ของผู้ขาย', style: TextStyle(fontSize: 20, color: Colors.blueGrey)),
    );
  }

  // สร้าง Widget แยกสำหรับเนื้อหาของหน้าโปรไฟล์ผู้ขาย (Index 2)
  Widget _buildSellerProfileContent() {
    ImageProvider<Object> profileImage;
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
              color: Color(0xFFE8F0F7), // Light blue background
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage, // เรียกใช้ฟังก์ชันเลือกและครอปรูปโปรไฟล์
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
                  // แสดงชื่อผู้ใช้จาก _currentSellerProfile หรือค่า default ถ้าเป็น null
                  _currentSellerProfile?.fullName ?? 'ชื่อ - นามสกุล', 
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  // แสดงเบอร์โทรศัพท์จาก _currentSellerProfile หรือค่า default ถ้าเป็น null
                  _currentSellerProfile?.phoneNumber ?? '099 999 9999', 
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                 Text(
                  // แสดงอีเมลจาก _currentSellerProfile หรือค่า default ถ้าเป็น null
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
                    // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerCreateStoreScreen(sellerProfile: widget.sellerProfile)));
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
                    // TODO: Implement logic to toggle shop status (requires Firebase/Backend)
                  },
                ),
                const SizedBox(height: 15),
                _buildActionButton(
                  text: 'ดูออเดอร์', 
                  color: const Color(0xFFE2CCFB),
                  onTap: () {
                    // หากผู้ขายกด "ดูออเดอร์" จากหน้านี้ ให้สลับไปที่ Index 1 ของ Bottom Navbar
                    _onItemTapped(1); 
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
                    // TODO: Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerProductManagementScreen()));
                  },
                ),
                const SizedBox(height: 30),
                _buildLogoutButton(), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันเลือกและครอปรูปภาพโปรไฟล์
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // ผู้ใช้ยกเลิกการเลือกรูปภาพ

    // ครอปรูปภาพ
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'ปรับแต่งรูปโปรไฟล์',
          toolbarColor: const Color(0xFF9C6ADE),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // ล็อกอัตราส่วนให้เป็นสี่เหลี่ยมจัตุรัส
          aspectRatioPresets: [
            CropAspectRatioPreset.square, // สำหรับรูปโปรไฟล์ แนะนำสี่เหลี่ยมจัตุรัส
          ],
        ),
        IOSUiSettings(
          title: 'ปรับแต่งรูปโปรไฟล์',
          aspectRatioLockEnabled: true, // ล็อกอัตราส่วน
          aspectRatioPickerButtonHidden: true, // ซ่อนปุ่มเลือกอัตราส่วน
          aspectRatioPresets: [
            CropAspectRatioPreset.square, // สำหรับรูปโปรไฟล์ แนะนำสี่เหลี่ยมจัตุรัส
          ],
        ),
      ],
    );

    if (croppedFile == null) return; // ผู้ใช้ยกเลิกการครอป

    File imageFile = File(croppedFile.path); // ใช้ไฟล์ที่ครอปแล้ว
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
      // _isLoading = true; // หากมี _isLoading state
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
          await FirebaseFirestore.instance.collection('sellers').doc(currentUser.uid).update({
            'profileImageUrl': downloadUrl,
          });

          // 3. อัปเดต UI ด้วยข้อมูลโปรไฟล์ใหม่
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
        // _isLoading = false; // หากมี _isLoading state
      });
    }
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

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async { // ทำให้เป็น async
        try {
          await FirebaseAuth.instance.signOut(); // เพิ่มการ sign out จาก Firebase
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
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e')),
          );
        }
      },
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

  // กำหนดชื่อ AppBar ตาม Index ที่ถูกเลือก
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'หน้าแรก'; // เปลี่ยนชื่อ AppBar เป็น "หน้าแรก"
      case 1:
        return 'รายการออเดอร์';
      case 2:
        return 'บัญชีผู้ขาย'; // หน้าโปรไฟล์
      default:
        return 'บ้านบ้านช้อป';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(), // ชื่อ AppBar เปลี่ยนตามหน้าที่เลือก
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F0F7),
        elevation: 0,
        leading: _selectedIndex != 0 ? IconButton( // แสดงปุ่ม Back ยกเว้นหน้าแรก (ฟีดโพสต์)
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            // Logic สำหรับปุ่ม Back ในแต่ละหน้าย่อย (ถ้ามี)
            // สำหรับหน้าโปรไฟล์ หรือออเดอร์ ถ้ากดปุ่มย้อนกลับ ให้กลับไปที่หน้าแรก (FeedPage)
            _onItemTapped(0); 
          },
        ) : null, // ถ้าเป็น Index 0 (หน้าแรก/ฟีดโพสต์) จะไม่มีปุ่ม Back
      ),
      body: IndexedStack(
        index: _selectedIndex, 
        children: _pages, 
      ),
      bottomNavigationBar: BottomNavbarWidget(
        selectedIndex: _selectedIndex, 
        onItemSelected: _onItemTapped, 
      ),
    );
  }
}
