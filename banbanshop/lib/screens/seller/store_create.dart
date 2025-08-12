// lib/screens/seller/store_create.dart

// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:uuid/uuid.dart';
import 'package:banbanshop/screens/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/edit_store_hours_screen.dart';

class StoreCreateScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const StoreCreateScreen({
    super.key,
    this.onRefresh,
  });

  @override
  State<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends State<StoreCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationAddressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedStoreType;
  File? _shopImageFile;
  bool _isUploading = false;
  bool _isFetchingInitialData = true;

  double? _selectedLatitude;
  double? _selectedLongitude;
  SellerProfile? _currentSellerProfile;

  late Map<String, dynamic> _operatingHours;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  final List<String> _storeTypes = [
    'อาหาร & เครื่องดื่ม',
    'เสื้อผ้า',
    'OTOP',
    'สิ่งของเครื่องใช้',
  ];

  @override
  void initState() {
    super.initState();
    _operatingHours = Store.defaultHours();
    _fetchSellerData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationAddressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellerData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isFetchingInitialData = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('sellers').doc(currentUser.uid).get();
      if (doc.exists) {
        setState(() {
          _currentSellerProfile = SellerProfile.fromJson(doc.data()!);
          _isFetchingInitialData = false;
        });
      } else {
         setState(() => _isFetchingInitialData = false);
      }
    } catch (e) {
      print("Error fetching seller data: $e");
      setState(() => _isFetchingInitialData = false);
    }
  }

  Future<void> _pickShopImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _shopImageFile = File(pickedFile.path);
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
        _selectedLatitude = result['latitude']!;
        _selectedLongitude = result['longitude']!;
        _locationAddressController.text = result['address']!;
      });
    }
  }

  Future<void> _editOpeningHours() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditStoreHoursScreen(
          initialHours: _operatingHours,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _operatingHours = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ตั้งค่าเวลาทำการแล้ว')),
      );
    }
  }

  Future<void> _createStore() async {
    if (!_formKey.currentState!.validate()) return;
    if (_shopImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกรูปภาพหน้าร้าน')));
      return;
    }
    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาปักหมุดตำแหน่งร้านบนแผนที่')));
      return;
    }
    if (_currentSellerProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลผู้ขาย กรุณาลองใหม่อีกครั้ง')));
      return;
    }

    setState(() => _isUploading = true);

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() => _isUploading = false);
      return;
    }

    String? shopImageUrl;
    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _shopImageFile!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'shop_images',
          uploadPreset: uploadPreset,
        ),
      );

      if (!response.isSuccessful || response.secureUrl == null) {
        throw 'อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}';
      }
      shopImageUrl = response.secureUrl;

      final String storeId = const Uuid().v4();
      final newStore = Store(
        id: storeId,
        ownerUid: currentUser.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedStoreType!,
        category: _selectedStoreType,
        imageUrl: shopImageUrl,
        locationAddress: _locationAddressController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        phoneNumber: _phoneNumberController.text.trim(),
        createdAt: DateTime.now(),
        province: _currentSellerProfile!.province,
        operatingHours: _operatingHours,
        isManuallyClosed: false, 
      );

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .set(newStore.toFirestore());

      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .update({
        'hasStore': true,
        'storeId': storeId,
        'shopName': _nameController.text.trim(),
        'shopAvatarImageUrl': shopImageUrl,
        'shopPhoneNumber': _phoneNumberController.text.trim(),
        'shopLatitude': _selectedLatitude,
        'shopLongitude': _selectedLongitude,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างร้านค้าสำเร็จ!')),
        );
        widget.onRefresh?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // White icon
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สร้างร้านค้าใหม่',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetchingInitialData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))) // Dark Purple loading
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickShopImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey[200], // Light grey background
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _shopImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(_shopImageFile!, fit: BoxFit.cover))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]), // Darker grey icon
                                  const SizedBox(height: 10),
                                  Text(
                                    'เพิ่มรูปหน้าร้าน',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 16), // Darker text
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'ชื่อร้านค้า',
                        hintText: 'ป้อนชื่อร้านค้าของคุณ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.store, color: Color(0xFF0288D1)), // Blue icon
                        focusedBorder: OutlineInputBorder( // Blue border when focused
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder( // Grey border when enabled
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาป้อนชื่อร้านค้า' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'คำอธิบายร้านค้า',
                        hintText: 'อธิบายเกี่ยวกับร้านค้าของคุณให้ลูกค้าทราบ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.description, color: Color(0xFF0288D1)), // Blue icon
                        focusedBorder: OutlineInputBorder( // Blue border when focused
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder( // Grey border when enabled
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาป้อนรายละเอียดร้านค้า' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedStoreType,
                      decoration: InputDecoration(
                        labelText: 'ประเภท/หมวดหมู่ร้านค้า',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.category, color: Color(0xFF0288D1)), // Blue icon
                        focusedBorder: OutlineInputBorder( // Blue border when focused
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder( // Grey border when enabled
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      items: _storeTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type, style: const TextStyle(color: Colors.black87)), // Darker text
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStoreType = newValue;
                        });
                      },
                      validator: (value) => (value == null) ? 'กรุณาเลือกประเภทร้านค้า' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationAddressController,
                      readOnly: true,
                      onTap: _pickLocationOnMap,
                      decoration: InputDecoration(
                        labelText: 'ที่ตั้งร้านค้า (เลือกจากแผนที่)',
                        hintText: _selectedLatitude == null
                            ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่'
                            : 'เลือกตำแหน่งแล้ว',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF0288D1)), // Blue icon
                        suffixIcon: const Icon(Icons.map, color: Color(0xFF0288D1)), // Blue icon
                        focusedBorder: OutlineInputBorder( // Blue border when focused
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder( // Grey border when enabled
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty || _selectedLatitude == null) ? 'กรุณาปักหมุดตำแหน่งร้านบนแผนที่' : null,
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _editOpeningHours,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'เวลาเปิด-ปิดร้าน',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.access_time, color: Color(0xFF0288D1)), // Blue icon
                          focusedBorder: OutlineInputBorder( // Blue border when focused
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder( // Grey border when enabled
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ตั้งค่าเวลาทำการ', style: TextStyle(fontSize: 16, color: Colors.black87)), // Darker text
                            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18), // Grey arrow
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทรศัพท์ร้าน',
                        hintText: 'ป้อนเบอร์โทรศัพท์สำหรับติดต่อร้าน',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFF0288D1)), // Blue icon
                        focusedBorder: OutlineInputBorder( // Blue border when focused
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        enabledBorder: OutlineInputBorder( // Grey border when enabled
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาป้อนเบอร์โทรศัพท์ร้าน' : null,
                    ),
                    const SizedBox(height: 32),

                    _isUploading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0))) // Dark Purple loading
                        : ElevatedButton(
                            onPressed: _createStore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A00E0), // Dark Purple button
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                              shadowColor: const Color(0xFF4A00E0).withOpacity(0.3), // Dark Purple shadow
                            ),
                            child: const Text(
                              'สร้างร้านค้า',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
