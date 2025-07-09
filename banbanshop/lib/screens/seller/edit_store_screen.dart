// lib/screens/seller/edit_store_screen.dart (ฉบับแก้ไขล่าสุด)

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:banbanshop/screens/models/store_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditStoreScreen extends StatefulWidget {
  final Store store;

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
  late TextEditingController _phoneNumberController;

  String? _selectedStoreType;
  String? _selectedProvince; // [EDIT] เพิ่ม State สำหรับจังหวัด
  File? _shopImageFile;
  String? _currentImageUrl;
  bool _isUploading = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  // [EDIT] เพิ่ม List ของจังหวัด
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
    'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย',
    'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู',
    'อ่างทอง', 'อุดรธานี', 'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ'
  ];

  final List<String> _storeTypes = [
    'OTOP',
    'อาหาร & เครื่องดื่ม',
    'เสื้อผ้า',
    'สิ่งของเครื่องใช้',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _descriptionController = TextEditingController(text: widget.store.description);
    _locationAddressController = TextEditingController(text: widget.store.locationAddress);
    _openingHoursController = TextEditingController(text: widget.store.openingHours);
    _phoneNumberController = TextEditingController(text: widget.store.phoneNumber);
    _selectedStoreType = widget.store.category;
    _selectedProvince = widget.store.province; // [EDIT] ตั้งค่าจังหวัดเริ่มต้น
    _currentImageUrl = widget.store.imageUrl;
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
    if (pickedFile != null) {
      setState(() {
        _shopImageFile = File(pickedFile.path);
        _currentImageUrl = null;
      });
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLatLng: (_selectedLatitude != null && _selectedLongitude != null)
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedLatitude = result['latitude'];
        _selectedLongitude = result['longitude'];
        _locationAddressController.text = result['address'];
      });
    }
  }

  Future<void> _updateStore() async {
    if (!_formKey.currentState!.validate()) return;
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

    setState(() => _isUploading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != widget.store.ownerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณไม่มีสิทธิ์แก้ไขร้านค้านี้')),
      );
      setState(() => _isUploading = false);
      return;
    }

    String? finalImageUrl = _currentImageUrl;
    try {
      if (_shopImageFile != null) {
        final response = await cloudinary.uploadResource(
          CloudinaryUploadResource(
            filePath: _shopImageFile!.path,
            resourceType: CloudinaryResourceType.image,
            folder: 'shop_images',
            uploadPreset: uploadPreset,
          ),
        );
        if (!response.isSuccessful || response.secureUrl == null) {
          throw 'อัปโหลดรูปภาพใหม่ไม่สำเร็จ: ${response.error}';
        }
        finalImageUrl = response.secureUrl;
      }

      final String newShopName = _nameController.text.trim();
      final updatedStoreData = {
        'name': newShopName,
        'description': _descriptionController.text.trim(),
        'type': _selectedStoreType!,
        'category': _selectedStoreType!,
        'province': _selectedProvince!, // [EDIT] เพิ่มการอัปเดตจังหวัด
        'imageUrl': finalImageUrl,
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

      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .update({
            'shopName': newShopName,
            'shopAvatarImageUrl': finalImageUrl,
            'shopPhoneNumber': _phoneNumberController.text.trim(),
            'shopLatitude': _selectedLatitude,
            'shopLongitude': _selectedLongitude,
          });

      final postsQuery = await FirebaseFirestore.instance
          .collection('posts')
          .where('storeId', isEqualTo: widget.store.id)
          .get();

      if (postsQuery.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in postsQuery.docs) {
          batch.update(doc.reference, {
            'shopName': newShopName,
            'avatarImageUrl': finalImageUrl,
          });
        }
        await batch.commit();
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อร้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาป้อนชื่อร้าน' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'รายละเอียดร้านค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาป้อนรายละเอียดร้านค้า' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStoreType,
                decoration: InputDecoration(
                  labelText: 'ประเภทร้านค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _storeTypes.map((String type) {
                  return DropdownMenuItem<String>(value: type, child: Text(type));
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedStoreType = newValue),
                validator: (v) => v == null ? 'กรุณาเลือกประเภทร้านค้า' : null,
              ),
              const SizedBox(height: 16),
              // [EDIT] เพิ่ม Dropdown สำหรับจังหวัด
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: 'จังหวัด',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _provinces.map((String province) {
                  return DropdownMenuItem<String>(value: province, child: Text(province));
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedProvince = newValue),
                validator: (v) => v == null ? 'กรุณาเลือกจังหวัด' : null,
              ),
              const SizedBox(height: 16),
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
                                Text('อัปโหลดรูปภาพหน้าร้าน', style: TextStyle(color: Colors.grey[600])),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ร้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.phone),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาป้อนเบอร์โทรศัพท์ร้าน' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationAddressController,
                readOnly: true,
                onTap: _pickLocationOnMap,
                decoration: InputDecoration(
                  labelText: 'ปักหมุดตำแหน่งร้าน',
                  hintText: _selectedLatitude == null ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่' : 'เลือกตำแหน่งแล้ว',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.map),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาปักหมุดตำแหน่งร้าน' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openingHoursController,
                decoration: InputDecoration(
                  labelText: 'ระยะเวลา เปิด-ปิดร้าน',
                  hintText: 'เช่น 09:00 - 18:00 น.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.access_time),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาป้อนระยะเวลาเปิด-ปิดร้าน' : null,
              ),
              const SizedBox(height: 32),
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
                  : ElevatedButton(
                      onPressed: _updateStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6ADE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                      ),
                      child: const Text('บันทึกการแก้ไข', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
