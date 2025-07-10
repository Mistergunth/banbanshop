// lib/screens/create_post.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/models/post_model.dart'; // ตรวจสอบว่า Post model อยู่ที่นี่
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth เพื่อดึง UID ของผู้ใช้
// ignore: unused_import
import 'package:banbanshop/screens/models/seller_profile.dart'; // Import SellerProfile

class CreatePostScreen extends StatefulWidget {
  final String shopName; // เพิ่ม shopName
  final String storeId; // เพิ่ม storeId

  const CreatePostScreen({
    super.key,
    required this.shopName, // กำหนดให้ required
    required this.storeId, // กำหนดให้ required
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image;
  final TextEditingController _captionController = TextEditingController();
  String? _selectedProvince;
  String? _selectedCategory;
  bool _isUploading = false; // สถานะการอัปโหลด

  // กำหนดค่า Cloudinary ของคุณที่นี่
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', apiKey: '157343641351425', apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- แทนที่ด้วย Cloud Name ของคุณ
    // apiKey และ apiSecret ไม่จำเป็นสำหรับ Unsigned Uploads
  );
  final String uploadPreset = 'flutter_unsigned_upload'; // <-- แทนที่ด้วยชื่อ Upload Preset ที่คุณสร้าง

  final List<String> _provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น',
    'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร',
    'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี',
    'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร',
    'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต',
    'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด',
    'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม',
    'สมุทรสาคร', 'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ',
  ];

  final List<String> _categories = [
    'OTOP', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'สิ่งของเครื่องใช้',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        // print('No image selected.');
      }
    });
  }

  void _postContent() async {
    if (_image == null || _captionController.text.isEmpty || _selectedProvince == null || _selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพ, เขียนข้อความ, เลือกจังหวัดและหมวดหมู่')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true; // เริ่มโหลด
    });

    String? uploadedImageUrl;
    User? currentUser = FirebaseAuth.instance.currentUser; // ดึงผู้ใช้ที่ล็อกอินอยู่

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อสร้างโพสต์')),
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // ดึงข้อมูลโปรไฟล์ผู้ขายจาก Firestore เพื่อดึง avatarImageUrl
    String avatarImageUrl = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png'; // รูป Avatar เริ่มต้น
    try {
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .get();

      if (sellerDoc.exists&& sellerDoc.data() != null) {
        //SellerProfile sellerProfile = SellerProfile.fromJson(sellerDoc.data() as Map<String, dynamic>);
        //avatarImageUrl = sellerProfile.profileImageUrl ?? avatarImageUrl; // ใช้รูปโปรไฟล์ของผู้ขาย
        final Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
        avatarImageUrl = sellerData['shopAvatarImageUrl'] ?? avatarImageUrl;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching seller shop avatar for post: $e');
      // ไม่ต้องแสดง SnackBar เพราะเป็นแค่ข้อมูลเสริม
    }

    try {
      // 1. อัปโหลดรูปภาพไปยัง Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _image!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'post_images', // ชื่อโฟลเดอร์สำหรับรูปโพสต์
          uploadPreset: uploadPreset, // ใช้ Upload Preset ที่สร้างไว้
        ),
      );

      if (response.isSuccessful) {
        uploadedImageUrl = response.secureUrl;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}')),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // 2. สร้าง Post object ใหม่
    final newPost = Post(
      id: '', // ID จะถูกสร้างโดย Firestore อัตโนมัติ
      shopName: widget.shopName, // ใช้ shopName ที่ได้รับมา
      createdAt: DateTime.now(),
      category: _selectedCategory!,
      title: _captionController.text,
      imageUrl: uploadedImageUrl!, // ใช้ URL ที่ได้จาก Cloudinary
      avatarImageUrl: avatarImageUrl,
      province: _selectedProvince!,
      productCategory: _selectedCategory!,
      ownerUid: currentUser.uid,
      storeId: widget.storeId, // ใช้ storeId ที่ได้รับมา
    );

    // 3. บันทึกข้อมูลโพสต์ลงใน Cloud Firestore
    try {
      // ใช้ add() เพื่อให้ Firestore สร้าง Document ID ให้อัตโนมัติ
      await FirebaseFirestore.instance.collection('posts').add(newPost.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์สำเร็จ!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกโพสต์: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false; // หยุดโหลด
      });
    }

    // ส่งโพสต์ใหม่กลับไปยังหน้า FeedPage (ถ้าต้องการให้ FeedPage อัปเดตทันที)
    if (mounted) {
      Navigator.pop(context, newPost); // ส่ง newPost กลับไป
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ส่วนสำหรับเลือกรูปภาพ
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _image != null
                        ? Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[600]),
                              const SizedBox(height: 10),
                              Text(
                                'แตะเพื่อเลือกรูปภาพ',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ส่วนสำหรับเขียนข้อความ/แคปชั่น
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'เขียนแคปชั่น...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.all(16.0),
                  ),
                ),
                const SizedBox(height: 20),

                // Dropdown สำหรับเลือกจังหวัด
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: 'เลือกจังหวัด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _provinces.map((String province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProvince = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
                ),
                const SizedBox(height: 20),

                // Dropdown สำหรับเลือกหมวดหมู่
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'เลือกหมวดหมู่',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ปุ่มกากบาท (ปิด)
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 28),
              onPressed: () {
                if (mounted) Navigator.pop(context);
              },
            ),
          ),

          // ปุ่มโพสต์
          Positioned(
            top: 40,
            right: 16,
            child: _isUploading
                ? const CircularProgressIndicator(color: Color(0xFF9C6ADE)) // แสดง Loading Indicator
                : TextButton(
                    onPressed: _postContent,
                    child: const Text(
                      'โพสต์',
                      style: TextStyle(
                        color: Color(0xFF9C6ADE),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}