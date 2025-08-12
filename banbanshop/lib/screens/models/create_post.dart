// lib/screens/create_post.dart
// ignore_for_file: avoid_print, use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/models/post_model.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Model สำหรับ Product (ควรแยกไปไฟล์ของตัวเอง) ---
class Product {
  final String id;
  final String name;

  Product({required this.id, required this.name});

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'ไม่มีชื่อ',
    );
  }
}


class CreatePostScreen extends StatefulWidget {
  final String shopName;
  final String storeId;

  const CreatePostScreen({
    super.key,
    required this.shopName,
    required this.storeId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final List<File> _images = [];
  final TextEditingController _captionController = TextEditingController();
  String? _selectedProvince;
  String? _selectedCategory;
  bool _isUploading = false;

  Product? _selectedProduct;
  List<Product> _sellerProducts = [];
  bool _isLoadingProducts = true;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', apiKey: '157343641351425', apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  final List<String> _provinces = [ 'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก', 'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี', 'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์', 'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย', 'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย', 'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู', 'อ่างทอง', 'อุดรธานี', 'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ',];
  final List<String> _categories = [ 'OTOP', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'สิ่งของเครื่องใช้', ];

  @override
  void initState() {
    super.initState();
    _fetchSellerProducts();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellerProducts() async {
    if (widget.storeId.isEmpty) {
      print("Error: storeId is empty. Cannot fetch products.");
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    try {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .get();
      if (mounted) {
        setState(() {
          _sellerProducts = productSnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      print("Error fetching products from sub-collection: $e");
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดสินค้า: $e')),
        );
      }
    }
  }

  // --- [แก้ไข] ฟังก์ชันแสดงตัวเลือกการนำเข้ารูปภาพ ---
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF8E2DE2)),
                title: const Text('เลือกจากคลังภาพ'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF4A00E0)),
                title: const Text('ถ่ายรูป'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- [เพิ่ม] ฟังก์ชันสำหรับเลือกจากคลังภาพ ---
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage(imageQuality: 70);

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((xFile) => File(xFile.path)).toList());
      });
    }
  }

  // --- [เพิ่ม] ฟังก์ชันสำหรับถ่ายภาพ ---
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }


  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _postContent() async {
    if (_images.isEmpty || _captionController.text.isEmpty || _selectedProvince == null || _selectedCategory == null || _selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    setState(() => _isUploading = true);

    List<String> uploadedImageUrls = [];
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อสร้างโพสต์')),
      );
      setState(() => _isUploading = false);
      return;
    }

    String avatarImageUrl = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
    try {
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
      if (storeDoc.exists && storeDoc.data() != null) {
        final Map<String, dynamic> storeData = storeDoc.data() as Map<String, dynamic>;
        avatarImageUrl = storeData['imageUrl'] ?? avatarImageUrl;
      }
    } catch (e) {
      print('Error fetching store avatar for post: $e');
    }

    try {
      for (var imageFile in _images) {
        final response = await cloudinary.uploadResource(
          CloudinaryUploadResource(
            filePath: imageFile.path,
            resourceType: CloudinaryResourceType.image,
            folder: 'post_images',
            uploadPreset: uploadPreset,
          ),
        );

        if (response.isSuccessful && response.secureUrl != null) {
          uploadedImageUrls.add(response.secureUrl!);
        } else {
          throw Exception('อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}');
        }
      }

      final newPost = Post(
        id: '',
        shopName: widget.shopName,
        createdAt: DateTime.now(),
        category: _selectedCategory!,
        title: _captionController.text,
        imageUrls: uploadedImageUrls,
        avatarImageUrl: avatarImageUrl,
        province: _selectedProvince!,
        productCategory: _selectedCategory!,
        ownerUid: currentUser.uid,
        storeId: widget.storeId,
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
      );

      await FirebaseFirestore.instance.collection('posts').add(newPost.toJson());
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โพสต์สำเร็จ!')));
      Navigator.pop(context, true); // Send true back to indicate success

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สร้างโพสต์ใหม่',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))),
            )
          else
            TextButton(
              onPressed: _postContent,
              child: const Text('โพสต์', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 24),

            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: _buildInputDecoration('เขียนแคปชั่น...').copyWith(
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            if (_isLoadingProducts)
              const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
            else
              _buildProductDropdown(),
            const SizedBox(height: 20),

            _buildProvinceDropdown(),
            const SizedBox(height: 20),

            _buildCategoryDropdown(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("รูปภาพ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: _images.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return _buildAddImageButton();
                    }
                    return _buildImageThumbnail(index);
                  },
                )
              : Center(
                  child: _buildAddImageButton(isPlaceholder: true),
                ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _images[index],
              fit: BoxFit.cover,
              width: 130,
              height: 130,
            ),
          ),
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton({bool isPlaceholder = false}) {
    return GestureDetector(
      onTap: _showImagePickerOptions, // --- [แก้ไข] เรียกใช้ฟังก์ชันที่แสดงตัวเลือก ---
      child: isPlaceholder
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF8E2DE2)),
                  SizedBox(height: 8),
                  Text('เพิ่มรูปภาพ', style: TextStyle(color: Colors.grey)), // --- [แก้ไข] ลบข้อความจำกัด 10 รูป ---
                ],
              ),
            )
          : Container(
              width: 130,
              height: 130,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add, color: Colors.grey, size: 40),
            ),
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<Product>(
      value: _selectedProduct,
      decoration: _buildInputDecoration('เลือกสินค้าที่จะโพสต์'),
      disabledHint: _sellerProducts.isEmpty ? const Text('คุณยังไม่มีสินค้าในร้าน') : null,
      items: _sellerProducts.map((Product product) {
        return DropdownMenuItem<Product>(
          value: product,
          child: Text(product.name, style: const TextStyle(color: Colors.black87)),
        );
      }).toList(),
      onChanged: _sellerProducts.isEmpty ? null : (Product? newValue) {
        setState(() => _selectedProduct = newValue);
      },
      validator: (value) => value == null ? 'กรุณาเลือกสินค้า' : null,
    );
  }

  Widget _buildProvinceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedProvince,
      decoration: _buildInputDecoration('เลือกจังหวัด'),
      items: _provinces.map((String province) => DropdownMenuItem<String>(value: province, child: Text(province))).toList(),
      onChanged: (String? newValue) => setState(() => _selectedProvince = newValue),
      validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
    );
  }
  
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _buildInputDecoration('เลือกหมวดหมู่'),
      items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
      onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
      validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
    );
  }
}
