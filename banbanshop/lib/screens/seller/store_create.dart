// lib/screens/seller/store_create.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Firestore
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // สำหรับ Cloudinary
import 'package:uuid/uuid.dart'; // สำหรับสร้าง UUID

// --- Store Model (สามารถย้ายไปไฟล์ models/store_model.dart ได้ในอนาคต) ---
class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type; // ประเภท/หมวดหมู่ร้านค้า
  final String? imageUrl; // URL รูปภาพหน้าร้าน
  final String location; // ตำแหน่งร้านค้า (อาจเป็น String ง่ายๆ ก่อน)
  final String openingHours; // ระยะเวลาเปิด-ปิดร้าน (String ง่ายๆ ก่อน)
  final DateTime createdAt;

  Store({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.location,
    required this.openingHours,
    required this.createdAt,
  });

  // Factory constructor สำหรับสร้าง Store จาก Firestore DocumentSnapshot
  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      ownerUid: data['ownerUid'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      type: data['type'] as String,
      imageUrl: data['imageUrl'] as String?,
      location: data['location'] as String,
      openingHours: data['openingHours'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method สำหรับแปลง Store เป็น Map สำหรับบันทึกลง Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      'location': location,
      'openingHours': openingHours,
      'createdAt': Timestamp.now(), // ใช้ Timestamp สำหรับ Firestore
    };
  }
}
// ---------------------------------------------------------------------

class StoreCreateScreen extends StatefulWidget {
  const StoreCreateScreen({super.key});

  @override
  State<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends State<StoreCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  String? _selectedStoreType;
  File? _shopImageFile;
  bool _isUploading = false;

  // กำหนดค่า Cloudinary ของคุณที่นี่ (ใช้ค่าเดียวกับ seller_account_screen.dart)
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- แทนที่ด้วย Cloud Name ของคุณ
    apiKey: '157343641351425', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- ต้องมีสำหรับ Signed Uploads/Deletion
  );
  final String uploadPreset = 'flutter_unsigned_upload'; // <-- ชื่อ Upload Preset ของคุณ

  final List<String> _storeTypes = [
    'อาหาร & เครื่องดื่ม',
    'เสื้อผ้า',
    'กีฬา & กิจกรรม',
    'สิ่งของเครื่องใช้',
    'บริการ',
    'อื่นๆ',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Future<void> _pickShopImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    setState(() {
      if (pickedFile != null) {
        _shopImageFile = File(pickedFile.path);
      } else {
        print('No image selected for shop.');
      }
    });
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_shopImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพหน้าร้าน')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อสร้างร้านค้า')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    String? shopImageUrl;
    try {
      // 1. อัปโหลดรูปภาพหน้าร้านไปยัง Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _shopImageFile!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'shop_images', // โฟลเดอร์สำหรับรูปภาพหน้าร้าน
          uploadPreset: uploadPreset,
        ),
      );

      if (response.isSuccessful) {
        shopImageUrl = response.secureUrl;
        if (shopImageUrl == null || shopImageUrl.isEmpty) {
          throw 'ไม่สามารถรับ URL รูปภาพจาก Cloudinary ได้';
        }
      } else {
        throw 'อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}';
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

    // 2. บันทึกข้อมูลร้านค้าลง Firestore
    try {
      final String storeId = const Uuid().v4(); // สร้าง ID ร้านค้า
      final newStore = Store(
        id: storeId,
        ownerUid: currentUser.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedStoreType!,
        imageUrl: shopImageUrl,
        location: _locationController.text.trim(),
        openingHours: _openingHoursController.text.trim(),
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('stores') // Collection สำหรับร้านค้า
          .doc(storeId)
          .set(newStore.toFirestore());

      // 3. อัปเดตข้อมูลผู้ขายใน Firestore เพื่อระบุว่ามีร้านค้าแล้ว
      // คุณอาจต้องการเพิ่มฟิลด์ 'hasStore' หรือ 'storeId' ใน collection 'sellers'
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .update({'hasStore': true, 'storeId': storeId}); // ตัวอย่าง

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างร้านค้าสำเร็จ!')),
        );
        Navigator.pop(context); // กลับไปยังหน้าก่อนหน้า (SellerAccountScreen)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูลร้านค้า: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สร้างร้านค้า',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ชื่อร้าน
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อร้าน',
                  hintText: 'ป้อนชื่อร้านของคุณ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนชื่อร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // รายละเอียดร้านค้า
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดร้านค้า',
                  hintText: 'อธิบายเกี่ยวกับร้านค้าของคุณ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนรายละเอียดร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ประเภทร้านค้า (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedStoreType,
                decoration: InputDecoration(
                  labelText: 'ประเภทร้านค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _storeTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStoreType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'กรุณาเลือกประเภทร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // อัปโหลดรูปภาพหน้าร้าน
              GestureDetector(
                onTap: _pickShopImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _shopImageFile != null
                      ? Image.file(_shopImageFile!, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'อัปโหลดรูปภาพหน้าร้าน',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ปักหมุดตำแหน่งร้าน
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'ปักหมุดตำแหน่งร้าน',
                  hintText: 'เช่น 123 ถนนสุขุมวิท, กรุงเทพฯ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนตำแหน่งร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ระยะเวลา เปิด-ปิดร้าน
              TextFormField(
                controller: _openingHoursController,
                decoration: InputDecoration(
                  labelText: 'ระยะเวลา เปิด-ปิดร้าน',
                  hintText: 'เช่น 09:00 - 18:00 น. ทุกวัน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.access_time),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนระยะเวลาเปิด-ปิดร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // ปุ่มสร้างร้านค้า
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
                  : ElevatedButton(
                      onPressed: _createStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6ADE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'สร้างร้านค้า',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
