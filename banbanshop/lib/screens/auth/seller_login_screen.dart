// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:banbanshop/screens/auth/seller_register_screen.dart'; // Import register screen
import 'package:banbanshop/screens/feed_page.dart'; // Import FeedPage
import 'package:banbanshop/screens/profile.dart'; // Import profile class
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController(); // For email
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Loading status

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginSeller() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Start loading
      });

      final String email = _usernameController.text.trim();
      final String password = _passwordController.text;

      try {
        // 1. Sign in with Email and Password via Supabase Auth
        final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        // Check if user is logged in
        if (response.user == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถเข้าสู่ระบบได้: ผู้ใช้ไม่ถูกต้อง')),
          );
          return;
        }

        final String userId = response.user!.id;

        // 2. Fetch seller profile data from Supabase 'sellers' table
        // Assuming 'sellers' table has 'id' column matching auth.users 'id'
        final List<Map<String, dynamic>> sellerData = await Supabase.instance.client
            .from('sellers')
            .select()
            .eq('id', userId)
            .limit(1) // Limit to 1 result
            .then((data) {
              if (data.isEmpty) {
                throw Exception('No seller profile found for this user.');
              }
              return data;
            });
        
        // Get the first (and only) seller profile
        final Map<String, dynamic> sellerDoc = sellerData.first;

        if (!mounted) return; // Check mounted before using BuildContext

        // Convert data from Supabase to SellerProfile object
        SellerProfile loggedInProfile = SellerProfile(
          fullName: sellerDoc['fullName'],
          phoneNumber: sellerDoc['phoneNumber'],
          idCardNumber: sellerDoc['idCardNumber'],
          province: sellerDoc['province'],
          email: sellerDoc['email'],
          password: '', // Password should not be stored in SellerProfile object
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
        );
        // Navigate to FeedPage, passing seller profile data
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

      } on AuthException catch (e) {
        if (!mounted) return; // Check mounted before using BuildContext
        String message;
        if (e.statusCode == '400') { // Bad request, often due to invalid credentials
          message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        } else {
          message = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        if (!mounted) return; // Check mounted before using BuildContext
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
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
                  label: 'อีเมล',
                  controller: _usernameController,
                  keyboardType: TextInputType.emailAddress, 
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกอีเมล';
                    }
                    // Validate email format
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
                    onPressed: _isLoading ? null : _loginSeller, // Disable button when loading
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white) // Show loading indicator
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
