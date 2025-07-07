// lib/main.dart (ฉบับแก้ไข)

import 'package:banbanshop/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:banbanshop/screens/feed_page.dart';
import 'package:banbanshop/screens/role_select.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช้อป',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class UserData {
  final SellerProfile? sellerProfile;
  final Store? storeProfile;
  UserData({this.sellerProfile, this.storeProfile});
}

// 1. เปลี่ยน AuthWrapper เป็น StatefulWidget
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // 2. สร้าง Key เพื่อใช้บังคับให้ FutureBuilder ทำงานใหม่
  Key _futureBuilderKey = UniqueKey();

  // 3. สร้างฟังก์ชันสำหรับรีเฟรช
  void _refreshData() {
    setState(() {
      // เมื่อ Key เปลี่ยน FutureBuilder จะถูกสร้างใหม่และเรียก future อีกครั้ง
      _futureBuilderKey = UniqueKey();
    });
  }

  Future<UserData?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot sellerDoc =
          await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

      if (!sellerDoc.exists) {
        return UserData(sellerProfile: null, storeProfile: null);
      }

      SellerProfile sellerProfile =
          SellerProfile.fromJson(sellerDoc.data() as Map<String, dynamic>);

      if (sellerProfile.hasStore == true && sellerProfile.storeId != null) {
        DocumentSnapshot storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(sellerProfile.storeId)
            .get();

        if (storeDoc.exists) {
          Store storeProfile = Store.fromFirestore(storeDoc);
          return UserData(sellerProfile: sellerProfile, storeProfile: storeProfile);
        }
      }
      return UserData(sellerProfile: sellerProfile, storeProfile: null);
    } catch (e) {
      // ignore: avoid_print
      print("Error fetching user data in AuthWrapper: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final User? user = snapshot.data;

        if (user == null) {
          return const RoleSelectPage();
        } else {
          return FutureBuilder<UserData?>(
            key: _futureBuilderKey, // 4. ผูก Key เข้ากับ FutureBuilder
            future: _fetchUserData(user.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              SellerProfile? sellerProfile = userSnapshot.data?.sellerProfile;
              Store? storeProfile = userSnapshot.data?.storeProfile;
              String initialProvince = sellerProfile?.province ?? 'ทั้งหมด';

              return FeedPage(
                selectedProvince: initialProvince,
                selectedCategory: 'ทั้งหมด',
                sellerProfile: sellerProfile,
                storeProfile: storeProfile,
                onRefresh: _refreshData, // 5. ส่งฟังก์ชัน refresh ลงไป
              );
            },
          );
        }
      },
    );
  }
}
