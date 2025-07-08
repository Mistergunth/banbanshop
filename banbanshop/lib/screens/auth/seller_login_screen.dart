// lib/screens/auth/seller_login_screen.dart (ฉบับแก้ไข)

// ignore_for_file: use_build_context_synchronously

import 'package:banbanshop/main.dart';
import 'package:flutter/material.dart';
import 'package:banbanshop/screens/auth/seller_register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginSeller() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final String loginInput = _loginController.text.trim();
    final String password = _passwordController.text;
    String? emailToLogin;

    try {
      // --- ตรรกะใหม่: ตรวจสอบว่าเป็นอีเมลหรือเบอร์โทร ---
      bool isEmail = loginInput.contains('@');

      if (isEmail) {
        emailToLogin = loginInput;
      } else {
        // ถ้าไม่ใช่ email, ให้สันนิษฐานว่าเป็นเบอร์โทร และค้นหา email ที่ผูกกัน
        // จัดรูปแบบเบอร์โทรให้เป็น +66... เพื่อให้ตรงกับข้อมูลใน Firestore
        String formattedPhone = loginInput;
        if (formattedPhone.startsWith('0')) {
          formattedPhone = "+66${formattedPhone.substring(1)}";
        } else if (formattedPhone.length == 9) {
          formattedPhone = "+66$formattedPhone";
        }

        final querySnapshot = await FirebaseFirestore.instance
            .collection('sellers')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          emailToLogin = querySnapshot.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(code: 'user-not-found', message: 'ไม่พบบัญชีผู้ใช้ด้วยเบอร์โทรศัพท์นี้');
        }
      }
      // ------------------------------------------------

      if (emailToLogin == null) {
         throw FirebaseAuthException(code: 'user-not-found', message: 'ไม่พบข้อมูลอีเมลสำหรับใช้เข้าสู่ระบบ');
      }

      // ทำการล็อคอินด้วย Email และ Password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      // ตรวจสอบว่าผู้ใช้ได้ยืนยันอีเมลแล้วหรือยัง
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณายืนยันอีเมลของคุณก่อนเข้าสู่ระบบ'),
            backgroundColor: Colors.orange,
          ),
        );
        await FirebaseAuth.instance.signOut(); // ออกจากระบบเพื่อให้ไปยืนยันก่อน
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
          (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง';
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
                const Text('ผู้ขาย - เข้าสู่ระบบ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInputField(
                  label: 'อีเมล หรือ เบอร์โทรศัพท์',
                  controller: _loginController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล หรือ เบอร์โทรศัพท์';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildPasswordField(
                  label: 'รหัสผ่าน',
                  controller: _passwordController,
                  isVisible: _isPasswordVisible,
                  onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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
                    onPressed: _isLoading ? null : _loginSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ยังไม่มีบัญชี?', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerRegisterScreen())),
                      child: const Text('สมัครสมาชิก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9B7DD9))),
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
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
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
}
