// lib/screens/auth/verify_email_screen.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends StatefulWidget {
  final User user;
  final Function() onVerified;
  const VerifyEmailScreen({super.key, required this.user, required this.onVerified});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false; 
  Timer? timer;
  // [KEY CHANGE] Use a state variable for the email to allow for updates.
  String? _displayEmail;

  @override
  void initState() {
    super.initState();
    
    // Initialize with the email from the passed user object.
    // It might be null initially due to the race condition.
    _displayEmail = widget.user.email;
    isEmailVerified = widget.user.emailVerified;

    if (!isEmailVerified) {
      // Start a timer to check for verification status periodically.
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
    
    // Allow resending email after a cooldown period.
    Future.delayed(const Duration(seconds: 30), () {
      if(mounted) {
        setState(() {
          canResendEmail = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // We need to reload to get the latest state from Firebase servers
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (!mounted || user == null) {
      timer?.cancel();
      return;
    }

    // [KEY FIX] If the display email was initially null, update it now.
    if (_displayEmail == null && user.email != null) {
      setState(() {
        _displayEmail = user.email;
      });
    }

    // Check if the user has verified their email
    if (user.emailVerified) {
      timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("ยืนยันอีเมลสำเร็จ! กำลังเข้าสู่ระบบ..."),
            backgroundColor: Colors.green),
      );
      widget.onVerified(); // Notify AuthWrapper to switch screens
    }
  }

  Future<void> sendVerificationEmail() async {
    setState(() => canResendEmail = false);

    try {
      // Use the most current user object to send the email
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ส่งอีเมลยืนยันอีกครั้งแล้ว"),
          backgroundColor: Colors.green,
        ),
      );
      // Re-enable the button after a cooldown
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) {
        setState(() => canResendEmail = true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: ${e.message ?? e.code}")),
        );
        // Re-enable button on error
        setState(() => canResendEmail = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('ยืนยันอีเมลของคุณ', style: GoogleFonts.kanit(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          // [KEY CHANGE] Show a loading indicator if the email hasn't been loaded yet.
          child: _displayEmail == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 100, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'อีเมลสำหรับยืนยันตัวตนได้ถูกส่งไปที่',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayEmail!, // It's guaranteed to be non-null here
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'กรุณาตรวจสอบกล่องจดหมาย (และโฟลเดอร์อีเมลขยะ) แล้วคลิกลิงก์เพื่อยืนยันบัญชีของคุณ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.kanit(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                    ),
                    onPressed: canResendEmail ? sendVerificationEmail : null,
                    icon: const Icon(Icons.email, color: Colors.white),
                    label: Text(canResendEmail ? 'ส่งอีเมลอีกครั้ง' : 'รอสักครู่...',
                        style: GoogleFonts.kanit(
                            fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      timer?.cancel();
                      FirebaseAuth.instance.signOut();
                    },
                    child: Text('ยกเลิกและกลับไปหน้าแรก',
                        style: GoogleFonts.kanit(color: Colors.grey)),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
