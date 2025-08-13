// lib/screens/seller/edit_payment_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/models/store_model.dart';

class EditPaymentScreen extends StatefulWidget {
  final Store store;

  const EditPaymentScreen({super.key, required this.store});

  @override
  State<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends State<EditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNameController;
  late TextEditingController _accountNumberController;
  String? _selectedBank;
  File? _qrImageFile;
  String? _currentQrImageUrl;
  bool _isLoading = false;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', 
    apiKey: '157343641351425', 
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', 
  );
  final String uploadPreset = 'flutter_unsigned_upload'; 

  final List<String> _thaiBanks = [
    'ธนาคารกรุงเทพ',
    'ธนาคารกสิกรไทย',
    'ธนาคารกรุงไทย',
    'ธนาคารทหารไทยธนชาต',
    'ธนาคารไทยพาณิชย์',
    'ธนาคารกรุงศรีอยุธยา',
    'ธนาคารออมสิน',
    'ธ.ก.ส.',
    'ธนาคารยูโอบี',
    'ธนาคารซีไอเอ็มบีไทย',
    'ธนาคารแลนด์ แอนด์ เฮ้าส์',
    'ธนาคารอิสลามแห่งประเทศไทย',
    'ธนาคารเกียรตินาคินภัทร',
    'ธนาคารทิสโก้',
  ];

  @override
  void initState() {
    super.initState();
    final paymentInfo = widget.store.paymentInfo;
    _accountNameController = TextEditingController(text: paymentInfo?['accountName'] ?? '');
    _accountNumberController = TextEditingController(text: paymentInfo?['accountNumber'] ?? '');
    _selectedBank = paymentInfo?['bankName'];
    _currentQrImageUrl = paymentInfo?['qrCodeImageUrl'];
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickQrImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _qrImageFile = File(pickedFile.path);
        _currentQrImageUrl = null; 
      });
    }
  }

  Future<void> _savePaymentInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_qrImageFile == null && _currentQrImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดรูปภาพ QR Code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _currentQrImageUrl;
      if (_qrImageFile != null) {
        final response = await cloudinary.uploadResource(
          CloudinaryUploadResource(
            filePath: _qrImageFile!.path,
            resourceType: CloudinaryResourceType.image,
            folder: 'payment_qr_codes',
            uploadPreset: uploadPreset,
          ),
        );

        if (!response.isSuccessful || response.secureUrl == null) {
          throw 'อัปโหลดรูปภาพ QR Code ไม่สำเร็จ: ${response.error}';
        }
        finalImageUrl = response.secureUrl;
      }

      final paymentData = {
        'accountName': _accountNameController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'bankName': _selectedBank,
        'qrCodeImageUrl': finalImageUrl,
      };

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.store.id)
          .update({'paymentInfo': paymentData});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลการชำระเงินสำเร็จ')),
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
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: const Text('ช่องทางการชำระเงิน'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickQrImage,
                child: Container(
                  height: 200,
                  width: 200,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Light grey background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400), // Lighter grey border
                  ),
                  child: _qrImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_qrImageFile!, fit: BoxFit.contain))
                      : (_currentQrImageUrl != null && _currentQrImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_currentQrImageUrl!, fit: BoxFit.contain))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey[600]), // Darker grey icon
                                const SizedBox(height: 8),
                                Text('แตะเพื่ออัปโหลด QR Code', style: TextStyle(color: Colors.grey[700])), // Darker text
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อบัญชี',
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'เลขที่บัญชี',
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกเลขที่บัญชี' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: InputDecoration(
                  labelText: 'ธนาคาร',
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
                items: _thaiBanks.map((String bank) {
                  return DropdownMenuItem<String>(value: bank, child: Text(bank, style: const TextStyle(color: Colors.black87))); // Darker text
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedBank = newValue),
                validator: (v) => v == null ? 'กรุณาเลือกธนาคาร' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
                  : ElevatedButton.icon(
                      onPressed: _savePaymentInfo,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกข้อมูล'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A00E0), // Dark Purple button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold , fontFamily: GoogleFonts.kanit().fontFamily),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
