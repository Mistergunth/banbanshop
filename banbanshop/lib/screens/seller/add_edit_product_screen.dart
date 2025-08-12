// lib/screens/seller/add_edit_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final String storeId;
  final Product? product; 

  const AddEditProductScreen({
    super.key,
    required this.storeId,
    this.product,
  });

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  File? _imageFile;
  String? _networkImageUrl;
  bool _isAvailable = true;
  bool _isUnlimitedStock = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController = TextEditingController(text: widget.product!.name);
      _descriptionController = TextEditingController(text: widget.product!.description);
      _priceController = TextEditingController(text: widget.product!.price.toString());
      _networkImageUrl = widget.product!.imageUrl;
      _isAvailable = widget.product!.isAvailable;
      _isUnlimitedStock = widget.product!.stock == -1;
      _stockController = TextEditingController(
        text: _isUnlimitedStock ? '' : widget.product!.stock.toString(),
      );
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _priceController = TextEditingController();
      _stockController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('product_images/${widget.storeId}/$fileName');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // ignore: avoid_print
      print("Image upload error: $e");
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_networkImageUrl == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มรูปภาพสินค้า')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _networkImageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
        if (imageUrl == null) {
          throw Exception('ไม่สามารถอัปโหลดรูปภาพได้');
        }
      }

      final Map<String, dynamic> productData = {
        'storeId': widget.storeId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'category': 'Default', 
        'isAvailable': _isAvailable,
        'stock': _isUnlimitedStock ? -1 : int.tryParse(_stockController.text.trim()) ?? 0,
      };


      if (widget.product == null) {
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('products')
            .add(productData);
      } else {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('products')
            .doc(widget.product!.id)
            .update(productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสินค้าสำเร็จ!')),
        );
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'เพิ่มสินค้าใหม่' : 'แก้ไขสินค้า'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProduct,
            color: Colors.white, // White icon
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : (_networkImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_networkImageUrl!, fit: BoxFit.cover))
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]), // Darker grey icon
                                  Text('เพิ่มรูปภาพสินค้า', style: TextStyle(color: Colors.grey[700])), // Darker text
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder( // Blue border when focused
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder( // Grey border when enabled
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'คำอธิบาย',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder( // Blue border when focused
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder( // Grey border when enabled
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'ราคา (บาท)',
                  prefixText: '฿ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder( // Blue border when focused
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder( // Grey border when enabled
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                  if (double.tryParse(v) == null) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('สินค้าพร้อมขาย', style: TextStyle(color: Colors.black87)), // Darker text
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                activeColor: const Color(0xFF0288D1), // Blue active color
              ),
              SwitchListTile(
                title: const Text('สต็อกไม่จำกัด', style: TextStyle(color: Colors.black87)), // Darker text
                value: _isUnlimitedStock,
                onChanged: (value) => setState(() => _isUnlimitedStock = value),
                activeColor: const Color(0xFF0288D1), // Blue active color
              ),
              if (!_isUnlimitedStock)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: 'จำนวนสต็อก',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder( // Blue border when focused
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder( // Grey border when enabled
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (!_isUnlimitedStock && (v == null || v.isEmpty)) {
                        return 'กรุณากรอกจำนวนสต็อก';
                      }
                      if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                        return 'กรุณากรอกจำนวนเต็ม';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A00E0), // Dark Purple button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3, // Added elevation
                    shadowColor: const Color(0xFF4A00E0).withOpacity(0.3), // Dark Purple shadow
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('บันทึกสินค้า', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Larger, bolder text
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
