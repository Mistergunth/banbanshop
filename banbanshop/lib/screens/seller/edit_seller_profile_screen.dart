// lib/screens/seller/edit_seller_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:flutter/services.dart';

class EditSellerProfileScreen extends StatefulWidget {
  final SellerProfile sellerProfile;
  final VoidCallback onProfileUpdated;

  const EditSellerProfileScreen({
    super.key,
    required this.sellerProfile,
    required this.onProfileUpdated,
  });

  @override
  State<EditSellerProfileScreen> createState() => _EditSellerProfileScreenState();
}

class _EditSellerProfileScreenState extends State<EditSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isVerifyingPhone = false;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.sellerProfile.fullName);
    _emailController = TextEditingController(text: widget.sellerProfile.email);
    _phoneController = TextEditingController(text: widget.sellerProfile.phoneNumber.replaceAll('+66', ''));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isVerifyingPhone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณายืนยันการเปลี่ยนเบอร์โทรศัพท์ให้เสร็จสิ้นก่อน')));
      return;
    }

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบผู้ใช้ปัจจุบัน')));
      setState(() => _isLoading = false);
      return;
    }

    try {
      final newFullName = _fullNameController.text.trim();
      final newEmail = _emailController.text.trim();
      bool hasChanges = false;
      bool emailChanged = false;

      if (newFullName != widget.sellerProfile.fullName) {
        await user.updateDisplayName(newFullName);
        await FirebaseFirestore.instance.collection('sellers').doc(user.uid).update({'fullName': newFullName});
        hasChanges = true;
      }


      if (newEmail != widget.sellerProfile.email) {
        await user.verifyBeforeUpdateEmail(newEmail);
        emailChanged = true;
        hasChanges = true;
      }
      
      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่มีการเปลี่ยนแปลงข้อมูล')));
      } else if (emailChanged) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกสำเร็จ! กรุณาตรวจสอบอีเมลใหม่และล็อกอินอีกครั้งเพื่อดูการเปลี่ยนแปลง'),
            duration: Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
      }

      widget.onProfileUpdated();
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
      if (e.code == 'user-token-expired' || e.code == 'requires-recent-login') {
        message = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้งเพื่อความปลอดภัย';
        await _auth.signOut();
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (e.code == 'email-already-in-use') {
        message = 'อีเมลนี้ถูกใช้งานโดยบัญชีอื่นแล้ว';
      } else {
        message = 'เกิดข้อผิดพลาดในการยืนยันตัวตน: ${e.message}';
      }
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _verifyAndupdatePhone() async {
    final newPhone = _phoneController.text.trim();
    final newPhoneWithCountryCode = "+66$newPhone";

    if (newPhoneWithCountryCode == widget.sellerProfile.phoneNumber) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เบอร์โทรศัพท์ไม่มีการเปลี่ยนแปลง')));
      return;
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: newPhoneWithCountryCode,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _updatePhoneCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ส่ง OTP ไม่สำเร็จ: ${e.message}")));
        if (mounted) setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
          _isVerifyingPhone = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _updatePhoneCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      await user.updatePhoneNumber(credential);
      await FirebaseFirestore.instance.collection('sellers').doc(user.uid).update({
        'phoneNumber': "+66${_phoneController.text.trim()}"
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตเบอร์โทรศัพท์สำเร็จ!')));
      widget.onProfileUpdated();
      setState(() {
        _isVerifyingPhone = false;
        _isLoading = false;
      });

    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("อัปเดตเบอร์โทรไม่สำเร็จ: $e")));
       if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์ผู้ขาย'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _fullNameController,
                label: 'ชื่อ - นามสกุล',
                validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'อีเมล',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                   if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                   if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                   return null;
                },
              ),
              const SizedBox(height: 4),
              const Text(
                'หากเปลี่ยนอีเมล ระบบจะส่งลิงก์ยืนยันไปที่อีเมลใหม่',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'เบอร์โทรศัพท์',
                prefixText: '+66 ',
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'กรุณากรอกเบอร์โทร';
                  if (value.length != 9) return 'ต้องมี 9 หลัก';
                  return null;
                },
              ),
              const SizedBox(height: 4),
              if (!_isVerifyingPhone)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _verifyAndupdatePhone,
                    child: const Text('เปลี่ยนเบอร์โทรศัพท์'),
                  ),
                ),
              
              if (_isVerifyingPhone)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                       _buildTextField(
                        controller: _otpController,
                        label: 'รหัส OTP',
                        keyboardType: TextInputType.number,
                        validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอก OTP' : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_verificationId != null) {
                            final credential = PhoneAuthProvider.credential(
                              verificationId: _verificationId!,
                              smsCode: _otpController.text.trim(),
                            );
                            _updatePhoneCredential(credential);
                          }
                        }, 
                        child: const Text('ยืนยัน OTP และอัปเดตเบอร์โทร'),
                      ),
                       TextButton(
                        onPressed: () => setState(() => _isVerifyingPhone = false),
                        child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('บันทึกการเปลี่ยนแปลง'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}
