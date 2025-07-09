// lib/screens/auth/buyer_register_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
import 'package:flutter/services.dart';

class BuyerRegisterScreen extends StatefulWidget {
  const BuyerRegisterScreen({super.key});

  @override
  State<BuyerRegisterScreen> createState() => _BuyerRegisterScreenState();
}

class _BuyerRegisterScreenState extends State<BuyerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFieldKey = GlobalKey<FormFieldState>();
  final _auth = FirebaseAuth.instance;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedProvince;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // --- State สำหรับ OTP ---
  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;
  // -----------------------

  final List<String> _provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น',
    'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร',
    'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี',
    'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร',
    'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต',
    'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด',
    'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม',
    'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย',
    'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู',
    'อ่างทอง', 'อุดรธานี', 'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_phoneFieldKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final phoneNumber = "+66${_phoneController.text.trim()}";

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        print("Auto verification completed");
        if(mounted) setState(() => _isLoading = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification Failed: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการส่ง OTP: ${e.code}")),
        );
        if (mounted) setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP ได้ถูกส่งไปยังเบอร์โทรศัพท์ของคุณแล้ว')),
        );
        setState(() {
          _isOtpSent = true;
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  void _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpSent || _verificationId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดส่งและยืนยัน OTP ก่อน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      // [KEY CHANGE 1] สร้างผู้ใช้ด้วยเบอร์โทรก่อน
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("ไม่สามารถยืนยันเบอร์โทรศัพท์ได้");
      }

      // [KEY CHANGE 2] ใช้ try-catch ซ้อนเพื่อจัดการกับการเชื่อมบัญชีโดยเฉพาะ
      try {
        final emailCredential = EmailAuthProvider.credential(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // พยายามเชื่อมบัญชีกับอีเมล
        await user.linkWithCredential(emailCredential);
      } catch (e) {
        // [KEY CHANGE 3] หากการเชื่อมล้มเหลว (เช่น อีเมลถูกใช้แล้ว) ให้ลบผู้ใช้ที่สร้างจากเบอร์โทรทิ้งทันที
        await user.delete();
        // ส่งต่อ error เดิมออกไปเพื่อให้ catch ด้านนอกจัดการ
        throw e;
      }
      
      // หากการเชื่อมสำเร็จ ให้ทำงานต่อไปตามปกติ
      await user.updateProfile(displayName: _fullNameController.text.trim());
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('buyers').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': "+66${_phoneController.text.trim()}",
        'province': _selectedProvince,
        'createdAt': Timestamp.now(),
        'isPhoneVerified': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณายืนยันอีเมลของคุณก่อนเข้าสู่ระบบ')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BuyerLoginScreen()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
      if (e.code == 'weak-password') {
        message = 'รหัสผ่านคาดเดาง่ายเกินไป';
      } else if (e.code == 'email-already-in-use' || e.code == 'credential-already-in-use') {
        // [KEY CHANGE 4] รวม error case เพื่อให้ครอบคลุม
        message = 'อีเมลหรือเบอร์โทรศัพท์นี้ถูกใช้งานโดยบัญชีอื่นแล้ว';
      } else if (e.code == 'invalid-verification-code') {
        message = 'รหัส OTP ไม่ถูกต้อง';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
      );
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
        title: const Text('บ้านบ้านช้อป', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ผู้ซื้อ - สมัครสมาชิก', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInputField(label: 'ชื่อ - นามสกุล', controller: _fullNameController, validator: (v) {
                  if (v!.isEmpty) return 'กรุณากรอกชื่อ';
                  if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$').hasMatch(v)) return 'ชื่อต้องเป็นตัวอักษรเท่านั้น';
                  return null;
                }),
                const SizedBox(height: 15),
                _buildInputField(label: 'อีเมล', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: (v) {
                  if (v!.isEmpty) return 'กรุณากรอกอีเมล';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                   return null;
                }),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        fieldKey: _phoneFieldKey,
                        label: 'เบอร์โทรศัพท์',
                        subLabel: '(ไม่ต้องใส่ 0 นำหน้า)',
                        controller: _phoneController,
                        prefixText: '+66 ',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                        validator: (v) {
                          if (v!.isEmpty) return 'กรุณากรอกเบอร์โทร';
                          if (v.length != 9) return 'ต้องมี 9 หลัก';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 44.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text(_isOtpSent ? 'ส่งอีกครั้ง' : 'ส่ง OTP'),
                      ),
                    )
                  ],
                ),
                if (_isOtpSent) ...[
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: 'รหัส OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'กรุณากรอก OTP' : null,
                  ),
                ],
                const SizedBox(height: 15),
                _buildProvinceDropdown(),
                const SizedBox(height: 15),
                _buildPasswordField(label: 'รหัสผ่าน', controller: _passwordController, isVisible: _isPasswordVisible, onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible), validator: (v) {
                  if (v!.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  return null;
                }),
                const SizedBox(height: 15),
                _buildPasswordField(label: 'ยืนยันรหัสผ่าน', controller: _confirmPasswordController, isVisible: _isConfirmPasswordVisible, onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible), validator: (v) {
                  if (v!.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                  if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                }),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerBuyer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('มีบัญชีอยู่แล้ว?', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen())),
                      child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9B7DD9))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? subLabel,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    Key? fieldKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        if (subLabel != null) ...[
          const SizedBox(height: 2),
          Text(subLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixText: prefixText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool isVisible, required VoidCallback onToggleVisibility, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('จังหวัด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('เลือกจังหวัด'),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: _provinces.map((String province) => DropdownMenuItem<String>(value: province, child: Text(province))).toList(),
          onChanged: (String? newValue) => setState(() => _selectedProvince = newValue),
          validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
        ),
      ],
    );
  }
}
