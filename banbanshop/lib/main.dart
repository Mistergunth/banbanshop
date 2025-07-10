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

  // [KEY CHANGE] Function signature now accepts the full User object
  Future<UserData?> _fetchUserData(User user) async {
    try {
      DocumentSnapshot userDoc;
      String userType = 'buyers'; // Assume buyer first

      // Check if user exists in 'sellers' collection
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
      
      if (sellerDoc.exists) {
        userDoc = sellerDoc;
        userType = 'sellers';
      } else {
        // If not a seller, assume they are a buyer and get their document
        userDoc = await FirebaseFirestore.instance.collection('buyers').doc(user.uid).get();
      }

      // --- Self-healing logic for email synchronization ---
      if (userDoc.exists) {
        final firestoreEmail = (userDoc.data() as Map<String, dynamic>)['email'];
        final authEmail = user.email;

        // If emails don't match, update Firestore with the latest from Auth
        if (firestoreEmail != authEmail && authEmail != null) {
          // ignore: avoid_print
          print('Email mismatch found. Syncing Firestore with Auth email...');
          await userDoc.reference.update({'email': authEmail});
          // Re-fetch the document to get the updated data for this session
          userDoc = await userDoc.reference.get();
        }
      }
      // --- End of self-healing logic ---

      // Proceed with fetching profile data using the (potentially updated) document
      if (userType == 'sellers' && userDoc.exists) {
         SellerProfile sellerProfile = SellerProfile.fromJson(userDoc.data() as Map<String, dynamic>);
         Store? storeProfile;
         if (sellerProfile.hasStore == true && sellerProfile.storeId != null) {
            DocumentSnapshot storeDoc = await FirebaseFirestore.instance
                .collection('stores')
                .doc(sellerProfile.storeId)
                .get();
            if (storeDoc.exists) {
              storeProfile = Store.fromFirestore(storeDoc);
            }
         }
         return UserData(sellerProfile: sellerProfile, storeProfile: storeProfile);
      } else {
        // For buyers or if data is somehow missing, return with no seller profile.
        // The FeedPage is designed to handle this gracefully.
        return UserData(sellerProfile: null, storeProfile: null);
      }

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
            // User is logged in and verified, show the main app
            return FutureBuilder<UserData?>(
              key: _futureBuilderKey,
              // [KEY CHANGE] Pass the full user object to _fetchUserData
              future: _fetchUserData(user),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                if (userSnapshot.hasError) {
                   return Scaffold(body: Center(child: Text("เกิดข้อผิดพลาด: ${userSnapshot.error}")));
                }
                
                // Even if userSnapshot.data is null (e.g., for a buyer),
                // we still proceed to FeedPage, which can handle null profiles.
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
