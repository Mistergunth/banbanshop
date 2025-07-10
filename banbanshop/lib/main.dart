// lib/main.dart

import 'package:banbanshop/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:banbanshop/screens/feed_page.dart';
import 'package:banbanshop/screens/role_select.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/auth/verify_email_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('th', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช้อป',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9B7DD9)),
        useMaterial3: true,
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('th', ''), // Thai
      ],
      locale: const Locale('th'),
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

  void _refreshAuthWrapper() {
    setState(() {});
  }

  Future<UserData?> _fetchUserData(String uid) async {
    try {
      DocumentSnapshot sellerDoc;
      for (int i = 0; i < 3; i++) {
        sellerDoc =
            await FirebaseFirestore.instance.collection('sellers').doc(uid).get();
        if (sellerDoc.exists) {
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
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 1500));
        }
      }
      return UserData(sellerProfile: null, storeProfile: null);
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

        if (snapshot.hasData && snapshot.data != null) {
          final User user = snapshot.data!;
          if (!user.emailVerified) {
            // [KEY CHANGE] Pass the user object directly to VerifyEmailScreen
            return VerifyEmailScreen(user: user, onVerified: _refreshAuthWrapper);
          } else {
            // User is logged in and verified, show the main app
            return FutureBuilder<UserData?>(
              key: _futureBuilderKey,
              future: _fetchUserData(user.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return Scaffold(
                      body: Center(
                          child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("ไม่สามารถโหลดข้อมูลผู้ใช้ได้"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: const Text("ลองอีกครั้ง"),
                      )
                    ],
                  )));
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
        } else {
          // User is not logged in
          return const RoleSelectPage();
        }
      },
    );
  }
}
