// lib/screens/buyer/add_edit_address_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:banbanshop/screens/map_picker_screen.dart'; // Import map picker
import 'package:banbanshop/screens/models/address_model.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address; // รับ address เข้ามาถ้าเป็นการแก้ไข, เป็น null ถ้าเป็นการสร้างใหม่

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
      // ถ้าเป็นการแก้ไข, ให้ตั้งค่าเริ่มต้นจากข้อมูลเดิม
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
        builder: (context) => MapPickerScreen(initialLatLng: _selectedLocation),
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
        // อัปเดตที่อยู่เดิม
        await collectionRef.doc(widget.address!.id).update(addressData);
      } else {
        // เพิ่มที่อยู่ใหม่
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
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(controller: _labelController, label: 'ป้ายกำกับ (เช่น บ้าน, ที่ทำงาน)'),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _nameController, label: 'ชื่อผู้รับ'),
              const SizedBox(height: 16),
              _buildTextFormField(controller: _phoneController, label: 'เบอร์โทรศัพท์', keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                readOnly: true,
                onTap: _pickLocationOnMap,
                decoration: InputDecoration(
                  labelText: 'ที่อยู่ (เลือกจากแผนที่)',
                  hintText: _selectedLocation == null ? 'แตะเพื่อเลือกตำแหน่ง' : 'เลือกตำแหน่งแล้ว',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  prefixIcon: const Icon(Icons.map_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'กรุณาเลือกที่อยู่จากแผนที่' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveAddress,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกที่อยู่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6ADE),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'กรุณากรอก$label';
        }
        return null;
      },
    );
  }
}
