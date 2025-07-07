// lib/screens/seller/store_create.dart

// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // For FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // For Cloudinary
import 'package:uuid/uuid.dart'; // For generating UUID
import 'package:banbanshop/screens/map_picker_screen.dart'; // Add import for MapPickerScreen
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add import for LatLng
import 'package:banbanshop/screens/models/store_model.dart'; // Add import Store model here
import 'package:banbanshop/screens/feed_page.dart'; // Import FeedPage for navigation

class StoreCreateScreen extends StatefulWidget {
  const StoreCreateScreen({super.key});

  @override
  State<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends State<StoreCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationAddressController = TextEditingController();
  final TextEditingController _openingHoursController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedStoreType;
  File? _shopImageFile;
  bool _isUploading = false;

  double? _selectedLatitude;
  double? _selectedLongitude;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- Replace with your Cloud Name
    apiKey: '157343641351425', // <-- Required for Signed Uploads/Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- Required for Signed Uploads/Deletion
  );
  final String uploadPreset = 'flutter_unsigned_upload'; // <-- Your Upload Preset Name

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
        _shopImageFile = File(pickedFile.path);
      } else {
        print('No image selected for shop.');
      }
    });
  }

  Future<void> _pickLocationOnMap() async {
    // Pass initialLatLng to MapPickerScreen if a location is already selected
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
      final double latitude = result['latitude']!;
      final double longitude = result['longitude']!;
      final String address = result['address']!; // Get address back

      setState(() {
        _selectedLatitude = latitude;
        _selectedLongitude = longitude;
        _locationAddressController.text = address; // Update Controller with address
      });
    }
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
      // 1. Upload shop image to Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _shopImageFile!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'shop_images', // Folder for shop images
          uploadPreset: uploadPreset,
        ),
      );

      if (response.isSuccessful) {
        shopImageUrl = response.secureUrl;
        if (shopImageUrl == null || shopImageUrl.isEmpty) {
          throw 'Cannot get image URL from Cloudinary';
        }
      } else {
        throw 'Image upload failed: ${response.error}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    // 2. Save store data to Firestore
    try {
      final String storeId = const Uuid().v4(); // Generate store ID
      final newStore = Store(
        id: storeId,
        ownerUid: currentUser.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedStoreType!,
        imageUrl: shopImageUrl,
        locationAddress: _locationAddressController.text.trim(), // Use locationAddress
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        openingHours: _openingHoursController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(), // Save phone number
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('stores') // Collection for stores
          .doc(storeId)
          .set(newStore.toFirestore()); // Use toFirestore() as per reference

      // 3. Update seller data in Firestore to indicate they have a store
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .update({
        'hasStore': true,
        'storeId': storeId,
        'shopName': _nameController.text.trim(), // Add shopName to SellerProfile
        'shopAvatarImageUrl': shopImageUrl, // Add shopAvatarImageUrl to SellerProfile
        'shopPhoneNumber': _phoneNumberController.text.trim(), // Add: Save shop phone number in seller profile
        'shopLatitude': _selectedLatitude, // Add: Save shop latitude in seller profile
        'shopLongitude': _selectedLongitude, // Add: Save shop longitude in seller profile
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สร้างร้านค้าสำเร็จ!')),
        );
        // Navigate back to FeedPage and remove all previous routes, passing null for required parameters
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const FeedPage(selectedProvince: null, selectedCategory: null)),
          (Route<dynamic> route) => false, // This makes sure all previous routes are removed
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving store data: $e')),
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
      backgroundColor: const Color(0xFFE8F4FD), // Change AppBar and Scaffold background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C6ADE), // Change AppBar background color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // Change back icon color
          onPressed: () {
            // Navigate back to FeedPage and remove all previous routes, passing null for required parameters
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const FeedPage(selectedProvince: null, selectedCategory: null)),
              (Route<dynamic> route) => false, // This makes sure all previous routes are removed
            );
          },
        ),
        title: const Text(
          'สร้างร้านค้าใหม่', // Change text to "Create New Store"
          style: TextStyle(
            color: Colors.white, // Change Title text color
            fontWeight: FontWeight.w500,
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
              // Upload shop image (improved UI)
              GestureDetector(
                onTap: _pickShopImage,
                child: Container(
                  height: 180, // Increase height
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // Add border radius
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
                          borderRadius: BorderRadius.circular(20), // Add border radius
                          child: Image.file(_shopImageFile!, fit: BoxFit.cover))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]), // Increase icon size
                            const SizedBox(height: 10),
                            Text(
                              'เพิ่มรูปหน้าร้าน', // Change text
                              style: TextStyle(color: Colors.grey[600], fontSize: 16), // Increase font size
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24), // Add spacing

              // Store Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อร้านค้า', // Change Label
                  hintText: 'ป้อนชื่อร้านค้าของคุณ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.store, color: Color(0xFF9C6ADE)), // Add icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนชื่อร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Store Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4, // Increase number of lines
                decoration: InputDecoration(
                  labelText: 'คำอธิบายร้านค้า', // Change Label
                  hintText: 'อธิบายเกี่ยวกับร้านค้าของคุณให้ลูกค้าทราบ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.description, color: Color(0xFF9C6ADE)), // Add icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนรายละเอียดร้านค้า';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Store Type (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedStoreType,
                decoration: InputDecoration(
                  labelText: 'ประเภท/หมวดหมู่ร้านค้า', // Change Label
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF9C6ADE)), // Add icon
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

              // Pin Store Location (linked to MapPickerScreen)
              TextFormField(
                controller: _locationAddressController,
                readOnly: true, // Make it non-editable directly
                onTap: _pickLocationOnMap, // Navigate to map screen on tap
                decoration: InputDecoration(
                  labelText: 'ที่ตั้งร้านค้า (เลือกจากแผนที่)', // Change Label
                  hintText: _selectedLatitude == null
                      ? 'แตะเพื่อเลือกตำแหน่งบนแผนที่'
                      : 'ตำแหน่งที่เลือก: ${_locationAddressController.text}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF9C6ADE)), // Add icon
                  suffixIcon: const Icon(Icons.map, color: Color(0xFF9C6ADE)), // Add map icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || _selectedLatitude == null) {
                    return 'กรุณาปักหมุดตำแหน่งร้านบนแผนที่';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Opening Hours
              TextFormField(
                controller: _openingHoursController,
                decoration: InputDecoration(
                  labelText: 'ระยะเวลาเปิด-ปิดร้าน', // Change Label
                  hintText: 'เช่น 09:00 - 18:00 น. ทุกวัน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.access_time, color: Color(0xFF9C6ADE)), // Add icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนระยะเวลาเปิด-ปิดร้าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Shop Phone Number
              TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'เบอร์โทรศัพท์ร้าน', // Change Label
                  hintText: 'ป้อนเบอร์โทรศัพท์สำหรับติดต่อร้าน',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), // Add border radius
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF9C6ADE)), // Add icon
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณาป้อนเบอร์โทรศัพท์ร้าน';
                  }
                  // You might add regex for valid phone number validation
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Create Store Button
              _isUploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE))) // Change CircularProgressIndicator color
                  : ElevatedButton(
                      onPressed: _createStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Change button background color
                        foregroundColor: const Color(0xFF9C6ADE), // Change button text color
                        padding: const EdgeInsets.symmetric(vertical: 18), // Increase padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), // Add border radius
                        ),
                        elevation: 5, // Add shadow
                      ),
                      child: const Text(
                        'สร้างร้านค้า',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Increase font size and make bold
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
