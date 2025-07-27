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
      title: 'บ้านบ้านช็อป',
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
  final String? userRole; // Add user role to UserData

  UserData({this.sellerProfile, this.storeProfile, this.userRole});
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

  Future<UserData?> _fetchUserData(User user) async {
    String? userRole;
    SellerProfile? sellerProfile;
    Store? storeProfile;
    DocumentSnapshot? userDoc;

    try {
      // Attempt 1: Fetch custom claims
      IdTokenResult idTokenResult = await user.getIdTokenResult(true); 
      Map<String, dynamic>? claims = idTokenResult.claims;
      userRole = claims?['role'];

      if (userRole == null) {
        print("Role claim not found on first attempt for user ${user.uid}. Waiting and retrying...");
        await Future.delayed(const Duration(seconds: 3)); 
        idTokenResult = await user.getIdTokenResult(true); 
        claims = idTokenResult.claims;
        userRole = claims?['role']; 
        if (userRole == null) {
          print("Role claim still not found after retry for user ${user.uid}. Returning null.");
          
          return null; 
        }
      }


      if (userRole == 'sellers') {
        userDoc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
        if (userDoc.exists) {
          sellerProfile = SellerProfile.fromJson(userDoc.data() as Map<String, dynamic>);
          if (sellerProfile.hasStore == true && sellerProfile.storeId != null) {
            DocumentSnapshot storeDoc = await FirebaseFirestore.instance
                .collection('stores')
                .doc(sellerProfile.storeId)
                .get();
            if (storeDoc.exists) {
              storeProfile = Store.fromFirestore(storeDoc);
            }
          }
        } else {
          print("User ${user.uid} claimed 'sellers' role but no seller document found. Logging out.");
          return null; 
        }
      } else if (userRole == 'buyers') {
        userDoc = await FirebaseFirestore.instance.collection('buyers').doc(user.uid).get();
        if (!userDoc.exists) {
          print("User ${user.uid} claimed 'buyers' role but no buyer document found. Logging out.");
          return null;
        }
      } else {
        print("User ${user.uid} has an unrecognized role claim: $userRole. Logging out.");
        return null;
      }

      if (userDoc != null && userDoc.exists) {
        final firestoreEmail = (userDoc.data() as Map<String, dynamic>)['email'];
        final String? authEmail = user.email;

        if (firestoreEmail != authEmail) {
          // ignore: avoid_print
          print('Email mismatch found. Syncing Firestore with Auth email...');
          await userDoc.reference.update({'email': authEmail});
          userDoc = await userDoc.reference.get();
        }
      }

      return UserData(sellerProfile: sellerProfile, storeProfile: storeProfile, userRole: userRole);

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
            return VerifyEmailScreen(user: user, onVerified: _refreshAuthWrapper);
          } else {
            return FutureBuilder<UserData?>(
              key: _futureBuilderKey,
              future: _fetchUserData(user),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (userSnapshot.hasError) {
                   return Scaffold(body: Center(child: Text("เกิดข้อผิดพลาด: ${userSnapshot.error}")));
                }
                
                final UserData? userData = userSnapshot.data;

                if (userData?.userRole == 'sellers') {
                  SellerProfile? sellerProfile = userData?.sellerProfile;
                  Store? storeProfile = userData?.storeProfile;
                  String initialProvince = sellerProfile?.province ?? 'ทั้งหมด';

                  return FeedPage(
                    selectedProvince: initialProvince,
                    selectedCategory: 'ทั้งหมด',
                    sellerProfile: sellerProfile,
                    storeProfile: storeProfile,
                    onRefresh: _refreshData,
                    isSeller: true,
                  );
                } else if (userData?.userRole == 'buyers') {
                  return FeedPage(
                    selectedProvince: 'ทั้งหมด', 
                    selectedCategory: 'ทั้งหมด',
                    sellerProfile: null,
                    storeProfile: null,
                    onRefresh: _refreshData,
                    isSeller: false,
                  );
                } else {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FirebaseAuth.instance.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่พบประเภทบัญชีของคุณ โปรดเข้าสู่ระบบใหม่')),
                    );
                  });
                  return const RoleSelectPage(); 
                }
              },
            );
          }
        } else {
          // ผู้ใช้ไม่ได้ล็อคอิน/ออกจากระบบ
          return const RoleSelectPage();
        }
      },
    );
  }
}
