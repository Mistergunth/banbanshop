// lib/screens/buyer/add_edit_address_screen.dart (ฉบับแก้ไข)

import 'package:banbanshop/screens/buyer/buyer_map_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:banbanshop/screens/models/address_model.dart';
import 'package:flutter/services.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final addr = widget.address!;
      _labelController.text = addr.label;
      _nameController.text = addr.contactName;
      _phoneController.text = addr.phoneNumber;
      _addressController.text = addr.addressLine;
      _selectedLocation = LatLng(addr.location.latitude, addr.location.longitude);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => BuyerMapPickerScreen(initialLatLng: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = LatLng(result['latitude']!, result['longitude']!);
        _addressController.text = result['address']!;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาปักหมุดตำแหน่งบนแผนที่')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด: ไม่พบข้อมูลผู้ใช้')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final addressData = {
      'label': _labelController.text.trim(),
      'contactName': _nameController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'addressLine': _addressController.text.trim(),
      'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
    };

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .collection('addresses');

      if (widget.address != null) {
        await collectionRef.doc(widget.address!.id).update(addressData);
      } else {
        await collectionRef.add(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกที่อยู่สำเร็จ!')),
        );
        Navigator.pop(context);
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
        title: Text(widget.address == null ? 'เพิ่มที่อยู่ใหม่' : 'แก้ไขที่อยู่'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0288D1), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                controller: _labelController,
                label: 'ป้ายกำกับ (เช่น บ้าน, ที่ทำงาน)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกป้ายกำกับ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                label: 'ชื่อผู้รับ',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อผู้รับ';
                  }
                  if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$').hasMatch(value)) {
                    return 'ชื่อต้องเป็นตัวอักษรเท่านั้น';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                keyboardType: TextInputType.phone,
                prefixText: '+66 ', // แสดง +66 ด้านหน้า
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9), // 
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (value.length != 9) {
                    return 'กรุณากรอกเบอร์โทรศัพท์ 9 หลัก (ไม่ต้องเติม 0 ข้างหน้า)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                readOnly: true,
                onTap: _pickLocationOnMap,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่ (เลือกจากแผนที่)',
                  hintText: _selectedLocation == null ? 'แตะเพื่อเลือกตำแหน่ง' : 'เลือกตำแหน่งแล้ว',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF0288D1)), // Blue icon
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'กรุณาเลือกที่อยู่จากแผนที่' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
                  : ElevatedButton.icon(
                      onPressed: _saveAddress,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกที่อยู่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1), // Blue button
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText, 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder( // Blue border when focused
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
        ),
        enabledBorder: OutlineInputBorder( // Grey border when enabled
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
      ),
      validator: validator,
    );
  }
}
