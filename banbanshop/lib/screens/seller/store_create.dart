// lib/screens/seller/store_create.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับ FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับ Firestore
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // สำหรับ Cloudinary
import 'package:uuid/uuid.dart'; // สำหรับสร้าง UUID
import 'package:banbanshop/screens/models/store_model.dart'; // <--- IMPORT Store MODEL จากที่ใหม่
import 'package:banbanshop/screens/map_picker_screen.dart'; // ตรวจสอบว่าไฟล์นี้มีอยู่จริงและคืนค่า LatLng + Address
import 'package:google_maps_flutter/google_maps_flutter.dart'; // สำหรับ LatLng object


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
  final TextEditingController _phoneNumberController = TextEditingController(); // เพิ่ม: Controller สำหรับเบอร์โทรศัพท์
  String? _selectedStoreType; // ประเภท/หมวดหมู่ร้านค้า
  File? _image;
  bool _isUploading = false;

  LatLng? _selectedLatLng; // เพิ่ม: สำหรับเก็บ Latitude และ Longitude ที่เลือกจากแผนที่
  String? _selectedAddress; // เพิ่ม: สำหรับเก็บที่อยู่ที่ได้จากการปักหมุด

  final List<String> _storeTypes = [
    'OTOP',
    'เสื้อผ้า',
    'อาหาร & เครื่องดื่ม',
    'สิ่งของเครื่องใช้',
  ];

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- แทนที่ด้วย Cloud Name ของคุณ
    apiKey: '157343641351425', // <-- ต้องมีสำหรับ Signed Uploads/Deletions
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- ต้องมีสำหรับ Signed Uploads/Deletions
  );

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // เมธอดสำหรับเลือกที่อยู่จากแผนที่
  Future<void> _selectLocationFromMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(), // นำทางไปยัง MapPickerScreen
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final LatLng latLng = result['latLng'];
      final String address = result['address'];

      setState(() {
        _selectedLatLng = latLng;
        _selectedAddress = address;
        _locationController.text = address; // แสดงที่อยู่ใน TextFormField
      });
    }
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ตรวจสอบว่ามีการเลือกที่อยู่จากแผนที่แล้ว
    if (_selectedLatLng == null || _selectedAddress == null || _selectedAddress!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาปักหมุดที่ตั้งร้านค้าบนแผนที่')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in.');
      }

      String? imageUrl;
      if (_image != null) {
        // ignore: deprecated_member_use
        final response = await cloudinary.uploadFile(
          filePath: _image!.path,
          resourceType: CloudinaryResourceType.image,
        );
        if (response.isSuccessful) {
          imageUrl = response.secureUrl;
        } else {
          throw Exception('Failed to upload image to Cloudinary: ${response.error}');
        }
      }

      final String storeId = const Uuid().v4(); // สร้าง ID สำหรับร้านค้า

      final Store newStore = Store(
        id: storeId,
        ownerUid: currentUser.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedStoreType!,
        imageUrl: imageUrl,
        location: _selectedAddress!, // ใช้ที่อยู่ที่ได้จากการปักหมุด
        latitude: _selectedLatLng!.latitude, // บันทึก latitude
        longitude: _selectedLatLng!.longitude, // บันทึก longitude
        openingHours: _openingHoursController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(), // เพิ่ม: เบอร์โทรศัพท์ร้านค้า
        createdAt: DateTime.now(),
      );

      // บันทึกข้อมูลร้านค้าลง Firestore ใน Collection 'stores'
      await FirebaseFirestore.instance.collection('stores').doc(storeId).set(newStore.toJson());

      // อัปเดตข้อมูลผู้ขายใน Collection 'sellers' เพื่อระบุว่ามีร้านค้าแล้ว
      await FirebaseFirestore.instance.collection('sellers').doc(currentUser.uid).update({
        'hasStore': true,
        'storeId': storeId,
        'shopName': _nameController.text.trim(),
        'shopAvatarImageUrl': imageUrl,
        'shopPhoneNumber': _phoneNumberController.text.trim(), // เพิ่ม: บันทึกเบอร์โทรศัพท์ร้านค้าในโปรไฟล์ผู้ขาย
        'shopLatitude': _selectedLatLng!.latitude, // บันทึก latitude ของร้านในโปรไฟล์ผู้ขาย
        'shopLongitude': _selectedLatLng!.longitude, // บันทึก longitude ของร้านในโปรไฟล์ผู้ขาย
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างร้านค้าสำเร็จ!')),
        );
        Navigator.pop(context); // กลับไปหน้าก่อนหน้า
      }
    } catch (e) {
      print('Error creating store: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการสร้างร้านค้า: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _openingHoursController.dispose();
    _phoneNumberController.dispose(); // เพิ่ม: Dispose controller เบอร์โทรศัพท์
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างร้านค้าใหม่'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ส่วนอัปโหลดรูปภาพ
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _image!,
                              fit: BoxFit.cover,
                              width: 150,
                              height: 150,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'เพิ่มรูปหน้าร้าน',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ชื่อร้านค้า
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อร้านค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนชื่อร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // คำอธิบายร้านค้า
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'คำอธิบายร้านค้า',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนคำอธิบายร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ประเภท/หมวดหมู่ร้านค้า
              DropdownButtonFormField<String>(
                value: _selectedStoreType,
                decoration: InputDecoration(
                  labelText: 'ประเภท/หมวดหมู่ร้านค้า',
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
                validator: (value) => value == null ? 'กรุณาเลือกประเภทร้านค้า' : null,
              ),
              const SizedBox(height: 20),

              // ที่ตั้งร้านค้า (แก้ไขให้เป็น ReadOnly และมีปุ่มเลือกจากแผนที่)
              TextFormField(
                controller: _locationController,
                readOnly: true, // ทำให้เป็น ReadOnly
                decoration: InputDecoration(
                  labelText: 'ที่ตั้งร้านค้า (เลือกจากแผนที่)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton( // เพิ่มปุ่มสำหรับเปิดแผนที่
                    icon: const Icon(Icons.map),
                    onPressed: _selectLocationFromMap,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาปักหมุดที่ตั้งร้านค้าบนแผนที่';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ระยะเวลาเปิด-ปิดร้าน
              TextFormField(
                controller: _openingHoursController,
                decoration: InputDecoration(
                  labelText: 'ระยะเวลาเปิด-ปิดร้าน (เช่น 9:00 - 18:00 น.)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.access_time),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนระยะเวลาเปิด-ปิดร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20), // เพิ่มระยะห่าง

              // เบอร์โทรศัพท์ร้านค้า
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ร้านค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone, // กำหนด keyboard เป็นเบอร์โทรศัพท์
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนเบอร์โทรศัพท์ร้านค้า';
                  }
                  // คุณสามารถเพิ่ม validation รูปแบบเบอร์โทรศัพท์ได้ที่นี่
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
