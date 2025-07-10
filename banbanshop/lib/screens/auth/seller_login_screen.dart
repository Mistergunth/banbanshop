// lib/screens/auth/seller_login_screen.dart

// ignore_for_file: use_build_context_synchronously

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
      bool isEmail = loginInput.contains('@');

      if (isEmail) {
        emailToLogin = loginInput;
      } else {
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
          // Throw a generic error to be caught below
          throw FirebaseAuthException(code: 'user-not-found');
        }
      }

      if (emailToLogin == null) {
         throw FirebaseAuthException(code: 'user-not-found');
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      // The AuthWrapper in main.dart will handle navigation after successful login.
      // No need to check for email verification here as AuthWrapper already does it.
      
      if (mounted) {
        // You can show a success message, but navigation is handled by AuthWrapper
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
        // );
      }

    } on FirebaseAuthException catch (e) {
      String message;
      // [KEY CHANGE] Consolidated error messages for a better user experience.
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'too-many-requests') {
        message = 'ตรวจพบกิจกรรมที่น่าสงสัย โปรดลองอีกครั้งในภายหลัง';
      }
      else {
        message = 'เกิดข้อผิดพลาด: กรุณาตรวจสอบข้อมูลและลองอีกครั้ง';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด')),
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
