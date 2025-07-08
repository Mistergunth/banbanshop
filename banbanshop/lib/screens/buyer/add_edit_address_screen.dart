// lib/screens/buyer/add_edit_address_screen.dart (OTP Verification)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:banbanshop/screens/buyer/buyer_map_picker_screen.dart';
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
  final _auth = FirebaseAuth.instance;

  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _otpController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isLoading = false;

  // --- State สำหรับ OTP ---
  bool _isOtpSent = false;
  String? _verificationId;
  bool _isPhoneVerified = false;
  String _originalPhoneNumber = '';
  // -----------------------

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final addr = widget.address!;
      _labelController.text = addr.label;
      _nameController.text = addr.contactName;
      _phoneController.text = addr.phoneNumber.startsWith('+66') ? addr.phoneNumber.substring(3) : addr.phoneNumber;
      _addressController.text = addr.addressLine;
      _selectedLocation = LatLng(addr.location.latitude, addr.location.longitude);
      _isPhoneVerified = true; // ถ้าเป็นการแก้ไข ให้ถือว่าเบอร์โทรยืนยันแล้ว
      _originalPhoneNumber = _phoneController.text;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _otpController.dispose();
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

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกเบอร์โทรศัพท์ 9 หลักให้ถูกต้อง')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = "+66${_phoneController.text.trim()}";

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการส่ง OTP: ${e.code}")),
        );
        if (mounted) setState(() => _isLoading = false);
      },
      codeSent: (verificationId, resendToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP ได้ถูกส่งไปยังเบอร์โทรศัพท์ของคุณแล้ว')),
        );
        setState(() {
          _isOtpSent = true;
          _verificationId = verificationId;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<void> _verifyOtpAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ถ้าเบอร์โทรไม่เปลี่ยนและยืนยันแล้ว ให้บันทึกเลย
    if (_isPhoneVerified && _phoneController.text == _originalPhoneNumber) {
      _saveAddress(null); // ส่ง null เพราะไม่ต้องใช้ credential
      return;
    }

    if (_otpController.text.isEmpty || _verificationId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัส OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      // แค่สร้าง credential เพื่อตรวจสอบว่า OTP ถูกต้องหรือไม่
      // ไม่ต้อง link กับ user เพราะนี่เป็นแค่การยืนยันเบอร์สำหรับที่อยู่
      // ในสถานการณ์จริง อาจจะต้อง re-authenticate user ก่อนเพื่อความปลอดภัย
      // แต่เพื่อความง่าย เราจะข้ามไปก่อน
      await _auth.signInWithCredential(credential); // การ signIn แค่เพื่อทดสอบ credential
      await _auth.signOut(); // ออกจากระบบทันทีหลังทดสอบ
      
      _saveAddress(credential);

    } on FirebaseAuthException catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('รหัส OTP ไม่ถูกต้อง: ${e.code}')),
      );
    } finally {
       if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddress(PhoneAuthCredential? credential) async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาปักหมุดตำแหน่งบนแผนที่')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fullPhoneNumber = "+66${_phoneController.text.trim()}";
    final addressData = {
      'label': _labelController.text.trim(),
      'contactName': _nameController.text.trim(),
      'phoneNumber': fullPhoneNumber,
      'addressLine': _addressController.text.trim(),
      'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
    };

    try {
      final collectionRef = FirebaseFirestore.instance.collection('buyers').doc(user.uid).collection('addresses');
      if (widget.address != null) {
        await collectionRef.doc(widget.address!.id).update(addressData);
      } else {
        await collectionRef.add(addressData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกที่อยู่สำเร็จ!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPhoneNumberChanged = _originalPhoneNumber != _phoneController.text;

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
              _buildTextFormField(controller: _nameController, label: 'ชื่อผู้รับ', validator: (v) {
                if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อผู้รับ';
                if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$').hasMatch(v)) return 'ชื่อต้องเป็นตัวอักษรเท่านั้น';
                return null;
              }),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _phoneController,
                      label: 'เบอร์โทรศัพท์',
                      prefixText: '+66 ',
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => setState(() {}), // เพื่อให้ UI อัปเดตเมื่อมีการเปลี่ยนแปลง
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทร';
                        if (v.length != 9) return 'ต้องมี 9 หลัก (ไม่ต้องใส่ 0)';
                        return null;
                      },
                    ),
                  ),
                  if (isPhoneNumberChanged || !_isPhoneVerified) ...[
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: _isLoading || _isOtpSent ? null : _sendOtp,
                        child: Text(_isOtpSent ? 'ส่งอีกครั้ง' : 'ส่ง OTP'),
                      ),
                    ),
                  ]
                ],
              ),
              if (_isOtpSent && (isPhoneNumberChanged || !_isPhoneVerified)) ...[
                const SizedBox(height: 16),
                _buildTextFormField(
                  controller: _otpController,
                  label: 'รหัส OTP',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก OTP' : null,
                ),
              ],
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
                      onPressed: (isPhoneNumberChanged && !_isOtpSent) ? null : _saveAddress,
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
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: validator,
    );
  }
}
