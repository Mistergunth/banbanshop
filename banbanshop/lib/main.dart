// lib/main.dart (ฉบับแก้ไขล่าสุด)

import 'package:banbanshop/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// --- 1. เพิ่ม Import ที่จำเป็น ---
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
// ---------------------------------

import 'package:banbanshop/screens/feed_page.dart';
import 'package:banbanshop/screens/role_select.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // --- 2. ตั้งค่าข้อมูลภาษาเริ่มต้น ---
  await initializeDateFormatting('th', null);
  // ---------------------------------
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
      // --- 3. เพิ่มการตั้งค่าภาษาให้กับ MaterialApp ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('th', ''), // Thai
      ],
      locale: const Locale('th'), // กำหนดให้ภาษาไทยเป็นภาษาเริ่มต้น
      // ---------------------------------------------
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Class สำหรับเก็บข้อมูลที่ดึงมาทั้งหมด
class UserData {
  final SellerProfile? sellerProfile;
  final Store? storeProfile;

  UserData({this.sellerProfile, this.storeProfile});
}

// เปลี่ยน AuthWrapper เป็น StatefulWidget
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Key _futureBuilderKey = UniqueKey();

  void _refreshData() {
    setState(() {
      _futureBuilderKey = UniqueKey();
    });
  }

  // [KEY CHANGE] แก้ไขฟังก์ชันนี้เพื่อแก้ปัญหา Race Condition
  Future<UserData?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot sellerDoc;

      // เพิ่มการ Retry เพื่อรอให้ Firestore เขียนข้อมูลเสร็จ
      // โดยจะพยายามค้นหา 3 ครั้ง ครั้งละ 1.5 วินาที
      for (int i = 0; i < 3; i++) {
        sellerDoc =
            await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

        if (sellerDoc.exists) {
          // ถ้าเจอข้อมูล seller ให้ทำงานต่อตามปกติ
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
        }

        // ถ้ายังไม่เจอ ให้รอ 1.5 วินาทีแล้วลองใหม่
        if (i < 2) { // จะไม่รอในครั้งสุดท้าย
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }

      // ถ้าลองครบ 3 ครั้งแล้วยังไม่เจอ หมายความว่าเป็น Buyer
      return UserData(sellerProfile: null, storeProfile: null);

    } catch (e) {
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
            key: _futureBuilderKey,
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
                onRefresh: _refreshData,
              );
            },
          );
        }
      },
    );
  }
}
