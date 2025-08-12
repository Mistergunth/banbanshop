// lib/screens/auth/buyer_login_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';

class BuyerLoginScreen extends StatefulWidget {
  const BuyerLoginScreen({super.key});

  @override
  State<BuyerLoginScreen> createState() => _BuyerLoginScreenState();
}

class _BuyerLoginScreenState extends State<BuyerLoginScreen> {
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

  Future<void> _loginBuyer() async {
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

        final sellerDoc = await FirebaseFirestore.instance.collection('sellers').where('email', isEqualTo: emailToLogin).limit(1).get();
        if (sellerDoc.docs.isNotEmpty) {
          throw FirebaseAuthException(code: 'email-is-seller', message: 'อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง');
        }

      } else {
        String formattedPhone = loginInput.replaceAll(RegExp(r'\D'), '');
        if (formattedPhone.startsWith('0')) {
          formattedPhone = "+66${formattedPhone.substring(1)}";
        } else if (formattedPhone.length == 9) {
          formattedPhone = "+66$formattedPhone";
        } else if (formattedPhone.startsWith('66') && formattedPhone.length == 11) {
          formattedPhone = "+$formattedPhone";
        }

        final querySnapshot = await FirebaseFirestore.instance
            .collection('buyers')
            .where('phoneNumber', isEqualTo: formattedPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          emailToLogin = querySnapshot.docs.first.data()['email'];
        } else {
          throw FirebaseAuthException(code: 'user-not-found', message: 'อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง');
        }
      }

      if (emailToLogin == null || emailToLogin.isEmpty) {
         throw FirebaseAuthException(code: 'user-not-found');
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToLogin,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'ไม่พบข้อมูลผู้ใช้งาน');
      }

      await user.reload();
      IdTokenResult idTokenResult = await user.getIdTokenResult(true);
      Map<String, dynamic>? claims = idTokenResult.claims;

      if (claims != null && claims['role'] == 'buyers') {
        if (!user.emailVerified) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('กรุณายืนยันอีเมลของคุณก่อนเข้าสู่ระบบ'),
              backgroundColor: Colors.orange,
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          await FirebaseAuth.instance.signOut();
          return;
        }
        // --- [การแก้ไข] เพิ่มคำสั่งปิดหน้าล็อกอินหลังจากสำเร็จ ---
        // เมื่อล็อกอินและตรวจสอบทุกอย่างเรียบร้อยแล้ว ให้ปิดหน้านี้
        // เพื่อให้ AuthWrapper แสดงหน้า FeedPage ขึ้นมา
        Navigator.pop(context);

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บัญชีนี้ไม่ใช่บัญชีผู้ซื้อ กรุณาเข้าสู่ระบบในฐานะผู้ขาย'),
            backgroundColor: Colors.red,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        await FirebaseAuth.instance.signOut();
        return;
      }

    } on FirebaseAuthException catch (e) {
      String message = 'อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง';
      if (e.code == 'too-many-requests') {
        message = 'ตรวจพบกิจกรรมที่น่าสงสัย โปรดลองอีกครั้งในภายหลัง';
      } else if (e.message != null && e.message!.contains('อีเมล/เบอร์โทร หรือรหัสผ่านไม่ถูกต้อง')) {
          message = e.message!;
      } else if (e.code == 'email-is-seller') {
          message = e.message!;
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
        title: const Text('บ้านบ้านช็อป', style: TextStyle(color: Colors.white,fontWeight: FontWeight.w600)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                    onPressed: _isLoading ? null : _loginBuyer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
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
