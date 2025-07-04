// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:banbanshop/screens/auth/seller_register_screen.dart'; // Import register screen
import 'package:banbanshop/screens/feed_page.dart'; // Import FeedPage
import 'package:banbanshop/screens/profile.dart'; // Import profile class
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

class SellerLoginScreen extends StatefulWidget {
  // เพิ่ม parameter เพื่อรับข้อมูลโปรไฟล์จากหน้าลงทะเบียน
  final SellerProfile? initialProfile; 

  const SellerLoginScreen({super.key, this.initialProfile});

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
  void initState() {
    super.initState();
    // ถ้ามี initialProfile ส่งมา ให้ตั้งค่าอีเมลเริ่มต้น
    if (widget.initialProfile != null) {
      _usernameController.text = widget.initialProfile!.email;
    }
  }

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

        // Check if user is logged in. response.user will be null if email not confirmed or wrong credentials.
        if (response.user == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่สามารถเข้าสู่ระบบได้: อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือยังไม่ได้ยืนยันอีเมล')),
          );
          return;
        }

        final String userId = response.user!.id;
        SellerProfile? loggedInProfile;

        // 2. Try to fetch seller profile data from Supabase 'sellers' table first
        try {
          final Map<String, dynamic>? sellerData = await Supabase.instance.client
              .from('sellers')
              .select()
              .eq('id', userId)
              .single() // Use single() to get a single row or null if not found
              .limit(1) // Limit to 1 result
              .maybeSingle(); // Use maybeSingle() to return null if no row found
          
          if (sellerData != null) {
            // Profile exists, load it
            loggedInProfile = SellerProfile.fromJson(sellerData);
          } else {
            // Profile does NOT exist, this is the first successful login after registration
            // Insert the actual seller profile data from initialProfile
            // If initialProfile is null (e.g., user navigated directly to login), use placeholders.
            final String userEmail = response.user!.email ?? '';

            await Supabase.instance.client
                .from('sellers')
                .insert({
                  'id': userId,
                  'fullName': widget.initialProfile?.fullName ?? 'ผู้ขายใหม่', // ใช้ข้อมูลจริงจาก initialProfile
                  'phoneNumber': widget.initialProfile?.phoneNumber ?? '0000000000', // ใช้ข้อมูลจริง
                  'idCardNumber': widget.initialProfile?.idCardNumber ?? '0000000000000', // ใช้ข้อมูลจริง
                  'province': widget.initialProfile?.province ?? 'ทั้งหมด', // ใช้ข้อมูลจริง
                  'email': userEmail, // ใช้อีเมลจาก Supabase Auth
                  'profile_image_url': null, // Initial empty profile image
                  'created_at': DateTime.now().toIso8601String(),
                });
            
            // Refetch the newly created profile to ensure it's loaded correctly
            final Map<String, dynamic>? newSellerData = await Supabase.instance.client
                .from('sellers')
                .select()
                .eq('id', userId)
                .single()
                .limit(1)
                .maybeSingle();
            
            if (newSellerData != null) {
              loggedInProfile = SellerProfile.fromJson(newSellerData);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('โปรไฟล์ผู้ขายถูกสร้างแล้ว!')),
              );
            } else {
              // This case should ideally not happen if insert was successful and RLS is correct
              throw Exception('Failed to retrieve newly created seller profile.');
            }
          }
        } on PostgrestException catch (e) {
          // Handle specific case of duplicate key if it somehow still occurs
          if (e.code == '23505') { // PostgreSQL unique violation error code
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('โปรไฟล์ผู้ขายสำหรับอีเมลนี้มีอยู่แล้ว')),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาดในการจัดการโปรไฟล์ผู้ขาย: ${e.message}')),
            );
          }
          await Supabase.instance.client.auth.signOut(); // Sign out to prevent inconsistent state
          return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการจัดการโปรไฟล์ผู้ขาย: $e')),
          );
          await Supabase.instance.client.auth.signOut();
          return;
        }

        if (!mounted) return; // Check mounted before using BuildContext

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ!')),
        );
        // Navigate to FeedPage, passing seller profile data
        Navigator.pushReplacement( 
          context,
          MaterialPageRoute(
            builder: (context) => FeedPage(
              selectedProvince: loggedInProfile?.province ?? 'ทั้งหมด', 
              selectedCategory: 'ทั้งหมด', 
              sellerProfile: loggedInProfile, 
            ),
          ),
        );

      } on AuthException catch (e) {
        if (!mounted) return; // Check mounted before using BuildContext
        String message;
        if (e.statusCode == '400') { // Bad request, often due to invalid credentials
          message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือยังไม่ได้ยืนยันอีเมล';
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
