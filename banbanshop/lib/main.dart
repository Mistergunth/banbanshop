import 'package:banbanshop/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:google_fonts/google_fonts.dart';

// Import หน้าหลัก (FeedPage) และหน้าเลือกบทบาท (RoleSelectPage)
import 'package:banbanshop/screens/feed_page.dart';
import 'package:banbanshop/screens/role_select.dart'; // ไฟล์ใหม่
import 'package:banbanshop/screens/models/seller_profile.dart'; // สำหรับ SellerProfile

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช้อป',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
      home: AuthWrapper(), // ใช้ AuthWrapper เพื่อจัดการการนำทางเริ่มต้น
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ฟังการเปลี่ยนแปลงสถานะการล็อกอิน
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // แสดงหน้าโหลดขณะรอตรวจสอบสถานะการล็อกอิน
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final User? user = snapshot.data;

        if (user == null) {
          // ถ้าไม่มีผู้ใช้ล็อกอินอยู่ ให้ไปหน้าเลือกบทบาท
          return const RoleSelectPage();
        } else {
          // ถ้ามีผู้ใช้ล็อกอินอยู่ ให้ตรวจสอบว่าเป็นผู้ซื้อหรือผู้ขาย
          // และนำทางไปยัง FeedPage พร้อมส่งข้อมูลโปรไฟล์ที่เกี่ยวข้อง
          return FutureBuilder<SellerProfile?>(
            future: _fetchSellerProfile(user.uid), // ดึงข้อมูลโปรไฟล์ผู้ขาย
            builder: (context, sellerSnapshot) {
              if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              SellerProfile? sellerProfile = sellerSnapshot.data;

              // กำหนดค่าเริ่มต้นสำหรับ selectedProvince และ selectedCategory
              // อาจจะดึงมาจาก SharedPreferences หรือ Firebase/Supabase สำหรับผู้ซื้อในอนาคต
              // สำหรับตอนนี้ ให้ใช้ค่าเริ่มต้น 'ทั้งหมด'
              String initialProvince = 'ทั้งหมด';
              String initialCategory = 'ทั้งหมด';

              return FeedPage(
                selectedProvince: initialProvince,
                selectedCategory: initialCategory,
                sellerProfile: sellerProfile, // ส่งข้อมูล sellerProfile ไปยัง FeedPage
              );
            },
          );
        }
      },
    );
  }

  // ฟังก์ชันสำหรับดึงข้อมูลโปรไฟล์ผู้ขายจาก Firestore
  // คล้ายกับที่ใช้ใน SellerAccountScreen แต่ใช้ใน main.dart เพื่อตรวจสอบบทบาท
  Future<SellerProfile?> _fetchSellerProfile(String uid) async {
    try {
      // ตรวจสอบใน collection 'sellers'
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(uid)
          .get();

      if (sellerDoc.exists) {
        return SellerProfile.fromJson(sellerDoc.data() as Map<String, dynamic>);
      }
      // ถ้าไม่พบใน sellers, อาจเป็นผู้ซื้อ (หรือยังไม่สร้างโปรไฟล์)
      return null;
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching seller profile in AuthWrapper: $e");
      return null;
    }
  }
}
