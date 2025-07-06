// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';
import 'package:banbanshop/screens/feed_page.dart'; // Import FeedPage เพื่อนำทางไป

class BuyerLoginScreen extends StatefulWidget {
  const BuyerLoginScreen({super.key});

  @override
  State<BuyerLoginScreen> createState() => _BuyerLoginScreenState();
}

class _BuyerLoginScreenState extends State<BuyerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginBuyer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // 1. เข้าสู่ระบบด้วย Firebase Auth
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // 2. แสดง SnackBar แจ้งเตือนว่าเข้าสู่ระบบสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
        );

        // 3. นำทางไปยังหน้า FeedPage และล้าง Navigation Stack ทั้งหมด
        // เพื่อไม่ให้ผู้ใช้กดปุ่มย้อนกลับมาหน้า Login ได้อีก
        if (mounted) { // ตรวจสอบว่า Widget ยัง mounted ก่อนใช้ BuildContext
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const FeedPage(
                selectedProvince: 'ทั้งหมด', // กำหนดค่าเริ่มต้นสำหรับผู้ซื้อ
                selectedCategory: 'ทั้งหมด', // กำหนดค่าเริ่มต้นสำหรับผู้ซื้อ
                sellerProfile: null, // ผู้ซื้อไม่มี sellerProfile
              ),
            ),
            (route) => false, // ล้างทุก Route ใน Stack
          );
        }

      } on FirebaseAuthException catch (e) {
        String message = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ';
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        } else if (e.code == 'invalid-email') {
          message = 'รูปแบบอีเมลไม่ถูกต้อง';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
        );
      } finally {
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
                const Text('ผู้ซื้อ - เข้าสู่ระบบ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildInputField(label: 'อีเมล', controller: _emailController, keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty ? 'กรุณากรอกอีเมล' : null),
                const SizedBox(height: 15),
                _buildPasswordField(label: 'รหัสผ่าน', controller: _passwordController, isVisible: _isPasswordVisible, onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible), validator: (v) => v!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginBuyer,
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
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerRegisterScreen())),
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

  // Helper Widgets (เหมือนกับหน้า Register)
  Widget _buildInputField({required String label, required TextEditingController controller, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      TextFormField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)), validator: validator)
    ]);
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool isVisible, required VoidCallback onToggleVisibility, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      TextFormField(controller: controller, obscureText: !isVisible, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200], contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), suffixIcon: IconButton(icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: onToggleVisibility)), validator: validator)
    ]);
  }
}
