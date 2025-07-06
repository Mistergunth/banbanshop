// lib/screens/seller/edit_store_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/seller/store_create.dart'; // สำหรับ Store Model
import 'package:banbanshop/screens/map_picker_screen.dart'; // สำหรับ MapPickerScreen
import 'package:geocoding/geocoding.dart'; // สำหรับ reverse geocoding

class EditStoreScreen extends StatefulWidget {
  final Store store; // รับ Store object เข้ามาเพื่อแก้ไข

  const EditStoreScreen({super.key, required this.store});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationAddressController;
  late TextEditingController _openingHoursController;
  late TextEditingController _phoneNumberController; // เพิ่มเบอร์โทร

  String? _selectedStoreType;
  File? _shopImageFile; // รูปภาพใหม่ที่ผู้ใช้อัปโหลด
  String? _currentImageUrl; // URL รูปภาพเดิมจาก Firestore
  bool _isUploading = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  final List<String> _storeTypes = [
    'อาหาร & เครื่องดื่ม',
    'เสื้อผ้า',
    'กีฬา & กิจกรรม',
    'สิ่งของเครื่องใช้',
    'บริการ',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นให้กับ Controller และตัวแปรจาก Store object ที่ได้รับมา
    _nameController = TextEditingController(text: widget.store.name);
    _descriptionController = TextEditingController(text: widget.store.description);
    _locationAddressController = TextEditingController(text: widget.store.locationAddress);
    _openingHoursController = TextEditingController(text: widget.store.openingHours);
    _phoneNumberController = TextEditingController(text: widget.store.phoneNumber); // กำหนดค่าเบอร์โทร

    _selectedStoreType = widget.store.type;
    _currentImageUrl = widget.store.imageUrl; // เก็บ URL รูปภาพเดิม
    _selectedLatitude = widget.store.latitude;
    _selectedLongitude = widget.store.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationAddressController.dispose();
    _openingHoursController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickShopImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    setState(() {
      if (pickedFile != null) {
        _shopImageFile = File(pickedFile.path); // รูปภาพใหม่ที่เลือก
        _currentImageUrl = null; // ล้าง URL รูปภาพเดิมออก ถ้ามีการเลือกรูปใหม่
      } else {
        print('No image selected for shop.');
      }
    });
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null && result is Map<String, double>) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
      });

      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(_selectedLatitude!, _selectedLongitude!);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _locationAddressController.text =
              '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea} ${p.postalCode}';
        }
      } catch (e) {
        print('Error getting address from coordinates: $e');
        _locationAddressController.text = 'ละติจูด: ${_selectedLatitude!.toStringAsFixed(4)}, ลองจิจูด: ${_selectedLongitude!.toStringAsFixed(4)}';
      }
    }
  }

  Future<void> _updateStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_shopImageFile == null && _currentImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพหน้าร้าน')),
      );
      return;
    }
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาปักหมุดตำแหน่งร้านบนแผนที่')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != widget.store.ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่มีสิทธิ์แก้ไขร้านค้านี้')),
      );
      setState(() {
        _isUploading = false;
      });
      return;
    }

    String? finalImageUrl = _currentImageUrl; // ใช้รูปภาพเดิมเป็นค่าเริ่มต้น
    if (_shopImageFile != null) { // ถ้ามีการเลือกรูปภาพใหม่
      try {
        // อัปโหลดรูปภาพใหม่
        final response = await cloudinary.uploadResource(
          CloudinaryUploadResource(
            filePath: _shopImageFile!.path,
            resourceType: CloudinaryResourceType.image,
            folder: 'shop_images',
            uploadPreset: uploadPreset,
          ),
        );

        if (response.isSuccessful) {
          finalImageUrl = response.secureUrl;
          if (finalImageUrl == null || finalImageUrl.isEmpty) {
            throw 'ไม่สามารถรับ URL รูปภาพใหม่จาก Cloudinary ได้';
          }
          // หากมีรูปภาพเก่าและมีการอัปโหลดรูปภาพใหม่สำเร็จ ให้ลบรูปภาพเก่าออกจาก Cloudinary
          if (widget.store.imageUrl != null && widget.store.imageUrl!.isNotEmpty) {
            try {
              final uri = Uri.parse(widget.store.imageUrl!);
              final pathSegments = uri.pathSegments;
              String publicId = pathSegments.last.split('.').first;
              if (pathSegments.length > 2) {
                publicId = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last.split('.').first}';
              }
              await cloudinary.deleteResource(publicId: publicId);
            } catch (e) {
              print('Warning: Failed to delete old image from Cloudinary: $e');
              // ไม่ต้อง throw error ที่นี่ เพราะการลบรูปเก่าไม่ควรบล็อกการอัปเดตข้อมูลร้าน
            }
          }
        } else {
          throw 'อัปโหลดรูปภาพใหม่ไม่สำเร็จ: ${response.error}';
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
    }

    // อัปเดตข้อมูลร้านค้าใน Firestore
    try {
      final updatedStoreData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedStoreType!,
        'imageUrl': finalImageUrl, // ใช้ URL รูปภาพใหม่หรือเดิม
        'locationAddress': _locationAddressController.text.trim(),
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'openingHours': _openingHoursController.text.trim(),
        'phoneNumber': _phoneNumberController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.store.id)
          .update(updatedStoreData);

      // อัปเดต shopName ใน SellerProfile ด้วย (ถ้ามีการเปลี่ยนชื่อร้าน)
      if (_nameController.text.trim() != widget.store.name) {
         await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .update({'shopName': _nameController.text.trim()});
      }


      if (mounted) {
        // ส่งค่า true กลับไปบอกว่ามีการอัปเดตสำเร็จ
        Navigator.pop(context, true);
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
          'แก้ไขข้อมูลร้านค้า',
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
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                          ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
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
                            )),
                ),
              ),
              const SizedBox(height: 16),

              // เบอร์โทรศัพท์ร้าน
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ร้าน',
                  hintText: 'ป้อนเบอร์โทรศัพท์สำหรับติดต่อร้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนเบอร์โทรศัพท์ร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ปักหมุดตำแหน่งร้าน (ผูกกับ MapPickerScreen)
              TextFormField(
                controller: _locationAddressController,
                readOnly: true,
                onTap: _pickLocationOnMap,
                decoration: InputDecoration(
                  labelText: 'ปักหมุดตำแหน่งร้าน',
                  hintText: _selectedLatitude == null
                      ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่'
                      : 'ตำแหน่งที่เลือก: ${_locationAddressController.text}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || _selectedLatitude == null) {
                    return 'กรุณาปักหมุดตำแหน่งร้านบนแผนที่';
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

              // ปุ่มบันทึกการแก้ไข
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
                  : ElevatedButton(
                      onPressed: _updateStore,
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
                        'บันทึกการแก้ไข',
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
