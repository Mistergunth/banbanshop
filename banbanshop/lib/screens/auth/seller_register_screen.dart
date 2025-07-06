
// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

import 'package:banbanshop/screens/profile.dart'; // ตรวจสอบให้แน่ใจว่า import ถูกต้อง
import 'package:banbanshop/screens/auth/seller_login_screen.dart'; // ใช้ auth/seller_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  SellerProfile profile = SellerProfile(
    fullName: '',
    phoneNumber: '',
    idCardNumber: '',
    province: '',
    password: '',
    email: '',
  );

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _idCardNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedProvince; // For dropdown
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // สถานะโหลด

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
    'สมุทรสาคร', 'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _idCardNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _registerSeller() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); 

      setState(() {
        _isLoading = true; // เริ่มโหลด
      });

      try {
        // 1. สมัครสมาชิกด้วย Email และ Password ผ่าน Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: profile.email,
          password: profile.password,
        );

        // 2. บันทึกข้อมูลโปรไฟล์ผู้ขายเพิ่มเติมลงใน Cloud Firestore
        // ใช้ UID ของผู้ใช้จาก Firebase Auth เป็น Document ID เพื่อให้ง่ายต่อการค้นหา
        await FirebaseFirestore.instance
            .collection('sellers') // ชื่อ Collection สำหรับผู้ขาย
            .doc(userCredential.user!.uid) // ใช้ UID เป็น Document ID
            .set({
              'fullName': profile.fullName,
              'phoneNumber': profile.phoneNumber,
              'idCardNumber': profile.idCardNumber,
              'province': profile.province,
              'email': profile.email,
              'uid': userCredential.user!.uid, // เก็บ UID ไว้ใน Firestore ด้วย
              // คุณสามารถเพิ่มข้อมูลอื่นๆ ที่ต้องการได้ที่นี่
            });

        if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ')),
        );
        _formKey.currentState!.reset(); // รีเซ็ตฟอร์ม
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SellerLoginScreen()),
        );

      } on FirebaseAuthException catch (e) {
        if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ BuildContext
        String message;
        if (e.code == 'weak-password') {
          message = 'รหัสผ่านอ่อนเกินไป';
        } else if (e.code == 'email-already-in-use') {
          message = 'อีเมลนี้ถูกใช้ไปแล้ว';
        } else {
          message = 'เกิดข้อผิดพลาดในการสมัครสมาชิก: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // หยุดโหลด
        });
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ผู้ขาย - สมัครสมาชิก',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  label: 'ชื่อ - นามสกุล',
                  controller: _fullNameController,
                  onSaved: (String? fullname) {
                    profile.fullName = fullname ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อ - นามสกุล';
                    }
                    if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$').hasMatch(value)) {
                      return 'กรุณากรอกชื่อ - นามสกุลให้ถูกต้อง (ตัวอักษรและเว้นวรรคเท่านั้น)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  label: 'อีเมล',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  onSaved: (String? email) {
                    profile.email = email ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    final bool isValidEmail = RegExp(
                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                    ).hasMatch(value);
                    if (!isValidEmail) {
                      return 'กรุณากรอกอีเมลให้ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildPhoneNumberField(), 
                const SizedBox(height: 15),
                _buildProvinceDropdown(), // เพิ่ม Dropdown จังหวัดที่นี่
                const SizedBox(height: 15),
                _buildPasswordField(
                  label: 'รหัสผ่าน', 
                  controller: _passwordController,
                  isVisible: _isPasswordVisible,
                  onSaved: (String? password) {
                    profile.password = password ?? '';
                  },
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildPasswordField(
                  label: 'ยืนยันรหัสผ่าน', 
                  controller: _confirmPasswordController,
                  isVisible: _isConfirmPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่าน';
                    }
                    if (value != _passwordController.text) {
                      return 'รหัสผ่านไม่ตรงกัน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  label: 'บัตรประชาชน', 
                  controller: _idCardNumberController,
                  keyboardType: TextInputType.number,
                  onSaved: (String? idCardNumber) {
                    profile.idCardNumber = idCardNumber ?? '';
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเลขบัตรประชาชน';
                    }
                    if (value.length != 13) {
                      return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'กรุณากรอกเฉพาะตัวเลข';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerSeller, // ปิดการใช้งานปุ่มเมื่อกำลังโหลด
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // แสดง loading indicator
                        : const Text(
                            'สมัครสมาชิก',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'มีบัญชีอยู่แล้ว?',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellerLoginScreen()),
                        );
                      },
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9B7DD9),
                        ),
                      ),
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
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เบอร์โทรศัพท์',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IntrinsicWidth(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: '+66',
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  items: <String>['+66'].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(value),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    // This can be expanded to allow other country codes
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                onSaved: (String? phoneNumber) {
                  profile.phoneNumber = phoneNumber ?? '';
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกเบอร์โทรศัพท์';
                  }
                  if (value.length != 10) {
                    return 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                  }
                  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                    return 'กรุณากรอกเฉพาะตัวเลข';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // สร้าง Dropdown สำหรับเลือกจังหวัด
  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'จังหวัดที่ตั้งร้าน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('เลือกจังหวัด'),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: _provinces.map((String province) {
            return DropdownMenuItem<String>(
              value: province,
              child: Text(province),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedProvince = newValue;
            });
          },
          onSaved: (String? value) {
            profile.province = value ?? ''; // บันทึกจังหวัดลงใน profile
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณาเลือกจังหวัด';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
          onSaved: onSaved,
        ),
      ],
    );
  }
}
