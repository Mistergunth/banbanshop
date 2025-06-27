// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:banbanshop/screens/auth/seller_register_screen.dart'; // Import register screen
import 'package:banbanshop/screens/feed_page.dart'; // Import FeedPage
import 'package:banbanshop/screens/profile.dart'; // Import profile class
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(); // For email (Firebase Auth uses email for login)
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // สถานะโหลด

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginSeller() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // เริ่มโหลด
      });

      final String email = _usernameController.text.trim(); // Firebase Auth ใช้ email
      final String password = _passwordController.text;

      try {
        // 1. เข้าสู่ระบบด้วย Email และ Password ผ่าน Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 2. ดึงข้อมูลโปรไฟล์ผู้ขายจาก Cloud Firestore
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(userCredential.user!.uid)
            .get();

        if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ BuildContext

        if (sellerDoc.exists) {
          // แปลงข้อมูลจาก Firestore เป็น SellerProfile object
          SellerProfile loggedInProfile = SellerProfile(
            fullName: sellerDoc['fullName'],
            phoneNumber: sellerDoc['phoneNumber'],
            idCardNumber: sellerDoc['idCardNumber'],
            province: sellerDoc['province'],
            email: sellerDoc['email'],
            password: '', // ไม่ควรเก็บรหัสผ่านใน SellerProfile object จริงๆ (แต่ในตัวอย่างนี้จำเป็นต้องมี field)
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
          );
          // นำทางไปยัง FeedPage โดยส่งข้อมูลโปรไฟล์ผู้ขายไปด้วย
          Navigator.pushReplacement( 
            context,
            MaterialPageRoute(
              builder: (context) => FeedPage(
                selectedProvince: loggedInProfile.province, 
                selectedCategory: 'ทั้งหมด', 
                sellerProfile: loggedInProfile, 
              ),
            ),
          );
        } else {
          // กรณีข้อมูลโปรไฟล์ผู้ขายไม่พบใน Firestore (แต่ล็อกอิน Auth สำเร็จ)
          // อาจเกิดขึ้นหากการบันทึกข้อมูลใน Firestore ล้มเหลวตอนสมัครสมาชิก
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบข้อมูลโปรไฟล์ผู้ขาย กรุณาติดต่อผู้ดูแลระบบ')),
          );
          // อาจจะให้ผู้ใช้ออกจากระบบ Firebase Auth ด้วย
          await FirebaseAuth.instance.signOut();
        }

      } on FirebaseAuthException catch (e) {
        if (!mounted) return; // ตรวจสอบ mounted ก่อนใช้ BuildContext
        String message;
        if (e.code == 'user-not-found') {
          message = 'ไม่พบผู้ใช้ด้วยอีเมลนี้';
        } else if (e.code == 'wrong-password') {
          message = 'รหัสผ่านไม่ถูกต้อง';
        } else if (e.code == 'invalid-email') {
          message = 'รูปแบบอีเมลไม่ถูกต้อง';
        } else {
          message = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${e.message}';
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
                  'ผู้ขาย - เข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'อีเมล', // เปลี่ยนเป็น "อีเมล" เพราะ Firebase Auth ใช้ Email
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress, 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    // ตรวจสอบรูปแบบอีเมลเท่านั้น
                    final bool isEmail = RegExp(
                      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
                    ).hasMatch(value);
                    if (!isEmail) {
                      return 'กรุณากรอกอีเมลให้ถูกรูปแบบ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildPasswordField(
                  label: 'รหัสผ่าน',
                  controller: _passwordController,
                  isVisible: _isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginSeller, // ปิดการใช้งานปุ่มเมื่อกำลังโหลด
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // แสดง loading indicator
                        : const Text(
                            'เข้าสู่ระบบ',
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
                      'ยังไม่มีบัญชี?',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellerRegisterScreen()),
                        );
                      },
                      child: const Text(
                        'สมัครสมาชิก',
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
        ),
      ],
    );
  }
}
