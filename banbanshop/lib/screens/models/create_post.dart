// lib/screens/create_post.dart
// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/models/post_model.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  File? _image;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  void _postContent() async {
    if (_image == null || _captionController.text.isEmpty || _selectedProvince == null || _selectedCategory == null || _selectedProduct == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ: รูปภาพ, แคปชั่น, จังหวัด, หมวดหมู่ และสินค้า')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    String? uploadedImageUrl;
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อสร้างโพสต์')),
        );
      }
      setState(() => _isUploading = false);
      return;
    }

    String avatarImageUrl = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';
    try {
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(currentUser.uid).get();
      if (sellerDoc.exists && sellerDoc.data() != null) {
        final Map<String, dynamic> sellerData = sellerDoc.data() as Map<String, dynamic>;
        avatarImageUrl = sellerData['shopAvatarImageUrl'] ?? avatarImageUrl;
      }
    } catch (e) {
      print('Error fetching seller shop avatar for post: $e');
    }

    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _image!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'post_images',
          uploadPreset: uploadPreset,
        ),
      );

      if (response.isSuccessful) {
        uploadedImageUrl = response.secureUrl;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: ${response.error}')));
        }
        setState(() => _isUploading = false);
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e')));
      }
      setState(() => _isUploading = false);
      return;
    }

    final newPost = Post(
      id: '',
      shopName: widget.shopName,
      createdAt: DateTime.now(),
      category: _selectedCategory!,
      title: _captionController.text,
      imageUrl: uploadedImageUrl!,
      avatarImageUrl: avatarImageUrl,
      province: _selectedProvince!,
      productCategory: _selectedCategory!,
      ownerUid: currentUser.uid,
      storeId: widget.storeId,
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
    );

    try {
      await FirebaseFirestore.instance.collection('posts').add(newPost.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โพสต์สำเร็จ!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกโพสต์: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!)),
                    child: _image != null ? Image.file(_image!, fit: BoxFit.cover) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[600]), const SizedBox(height: 10), Text('แตะเพื่อเลือกรูปภาพ', style: TextStyle(color: Colors.grey[600], fontSize: 16))]),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: 'เขียนแคปชั่น...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.all(16.0)),
                ),
                const SizedBox(height: 20),

                _isLoadingProducts
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
                    : DropdownButtonFormField<Product>(
                        value: _selectedProduct,
                        decoration: InputDecoration(
                          labelText: 'เลือกสินค้าที่จะโพสต์',
                          hintText: _sellerProducts.isEmpty ? 'คุณยังไม่มีสินค้าในร้าน' : 'เลือกสินค้า',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        disabledHint: _sellerProducts.isEmpty ? const Text('คุณยังไม่มีสินค้าในร้าน') : null,
                        items: _sellerProducts.map((Product product) {
                          return DropdownMenuItem<Product>(
                            value: product,
                            child: Text(product.name),
                          );
                        }).toList(),
                        onChanged: _sellerProducts.isEmpty ? null : (Product? newValue) {
                          setState(() {
                            _selectedProduct = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'กรุณาเลือกสินค้า' : null,
                      ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(labelText: 'เลือกจังหวัด', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: _provinces.map((String province) => DropdownMenuItem<String>(value: province, child: Text(province))).toList(),
                  onChanged: (String? newValue) => setState(() => _selectedProvince = newValue),
                  validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: 'เลือกหมวดหมู่', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
                  onChanged: (String? newValue) => setState(() => _selectedCategory = newValue),
                  validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: _isUploading
                ? const CircularProgressIndicator(color: Color(0xFF9C6ADE))
                : TextButton(
                    onPressed: _postContent,
                    child: const Text('โพสต์', style: TextStyle(color: Color(0xFF9C6ADE), fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }
}
