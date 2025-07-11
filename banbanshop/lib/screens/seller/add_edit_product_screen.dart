// lib/screens/seller/add_edit_product_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
// --- [KEY FIX] Add the missing import for Firestore ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final String storeId;
  final Product? product; // If null, it's a new product. Otherwise, editing.

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
      // Editing existing product
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
      // Creating new product
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

      final productData = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        imageUrl: imageUrl,
        category: 'Default', // Placeholder, can be expanded later
        isAvailable: _isAvailable,
        stock: _isUnlimitedStock ? -1 : int.tryParse(_stockController.text.trim()) ?? 0,
      ).toFirestore();

      if (widget.product == null) {
        // Create new product
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('products')
            .add(productData);
      } else {
        // Update existing product
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
        Navigator.pop(context, true); // Pop with a result to indicate success
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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProduct,
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
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (_networkImageUrl != null
                          ? Image.network(_networkImageUrl!, fit: BoxFit.cover)
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: 50),
                                  Text('เพิ่มรูปภาพสินค้า'),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'ราคา (บาท)', prefixText: '฿ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกราคา';
                  if (double.tryParse(v) == null) return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('สินค้าพร้อมขาย'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              SwitchListTile(
                title: const Text('สต็อกไม่จำกัด'),
                value: _isUnlimitedStock,
                onChanged: (value) => setState(() => _isUnlimitedStock = value),
              ),
              if (!_isUnlimitedStock)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextFormField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'จำนวนสต็อก'),
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
                  child: _isLoading ? const CircularProgressIndicator() : const Text('บันทึกสินค้า'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
