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
      IdTokenResult idTokenResult = await user.getIdTokenResult(true); // Forces refresh
      Map<String, dynamic>? claims = idTokenResult.claims;
      userRole = claims?['role'];

      // [KEY FIX] If role is still null after first attempt, wait and retry once
      // This handles the delay in Cloud Function setting claims after registration.
      if (userRole == null) {
        print("Role claim not found on first attempt for user ${user.uid}. Waiting and retrying...");
        await Future.delayed(const Duration(seconds: 3)); // Wait a bit for Cloud Function to set claims
        idTokenResult = await user.getIdTokenResult(true); // Retry fetching token with refreshed claims
        claims = idTokenResult.claims;
        userRole = claims?['role']; // Get role again
        if (userRole == null) {
          print("Role claim still not found after retry for user ${user.uid}. Returning null.");
          // If role is still null after retry, it's genuinely missing or delayed too much.
          // Returning null will trigger the fallback to RoleSelectPage.
          return null; 
        }
      }

      // [KEY FIX] Strictly use userRole from claims to fetch data from the CORRECT collection
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
          // If userRole is 'sellers' but no seller document exists, it's an inconsistency.
          // This user is claiming to be a seller but has no seller profile data.
          print("User ${user.uid} claimed 'sellers' role but no seller document found. Logging out.");
          return null; // This will lead to a null UserData, which AuthWrapper's builder will handle by signing out.
        }
      } else if (userRole == 'buyers') {
        userDoc = await FirebaseFirestore.instance.collection('buyers').doc(user.uid).get();
        if (!userDoc.exists) {
          // If userRole is 'buyers' but no buyer document exists, it's an inconsistency.
          // This user is claiming to be a buyer but has no buyer profile data.
          print("User ${user.uid} claimed 'buyers' role but no buyer document found. Logging out.");
          return null; // This will lead to a null UserData, which AuthWrapper's builder will handle by signing out.
        }
        // No specific buyer profile model in your code, so just confirm existence.
      } else {
        // This case should ideally be caught by the initial userRole == null check.
        // But as a safeguard, if userRole is an unrecognized string.
        print("User ${user.uid} has an unrecognized role claim: $userRole. Logging out.");
        return null;
      }

      // --- Self-healing logic for email synchronization (keep this) ---
      if (userDoc != null && userDoc.exists) {
        final firestoreEmail = (userDoc.data() as Map<String, dynamic>)['email'];
        final String? authEmail = user.email;

        // If authEmail is not null, and it's different from firestoreEmail, then sync
        if (firestoreEmail != authEmail) { // This condition is now correct.
          // ignore: avoid_print
          print('Email mismatch found. Syncing Firestore with Auth email...');
          await userDoc.reference.update({'email': authEmail});
          // Re-fetch the document to get the updated data for this session
          userDoc = await userDoc.reference.get();
        }
      }
      // --- End of self-healing logic ---
      
      // Return UserData with the determined role
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
            // If email is not verified, always go to VerifyEmailScreen
            return VerifyEmailScreen(user: user, onVerified: _refreshAuthWrapper);
          } else {
            // User is logged in and email is verified
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
                
                // Get user data including role from userSnapshot
                final UserData? userData = userSnapshot.data;

                // Conditional routing based on role
                if (userData?.userRole == 'sellers') {
                  SellerProfile? sellerProfile = userData?.sellerProfile;
                  Store? storeProfile = userData?.storeProfile;
                  String initialProvince = sellerProfile?.province ?? 'ทั้งหมด';

                  return FeedPage( // Assuming FeedPage is shared, or navigate to SellerDashboard
                    selectedProvince: initialProvince,
                    selectedCategory: 'ทั้งหมด',
                    sellerProfile: sellerProfile, // Pass seller profile for seller-specific UI
                    storeProfile: storeProfile,
                    onRefresh: _refreshData,
                    isSeller: true, // Explicitly true for sellers
                  );
                } else if (userData?.userRole == 'buyers') {
                  // For buyers, sellerProfile and storeProfile should be null
                  return FeedPage( // Navigate to Buyer's Feed Page
                    selectedProvince: 'ทั้งหมด', // Buyers don't have a specific province from profile
                    selectedCategory: 'ทั้งหมด',
                    sellerProfile: null, // Ensure sellerProfile is null for buyers
                    storeProfile: null,
                    onRefresh: _refreshData,
                    isSeller: false, // Explicitly false for buyers
                  );
                } else {
                  // Fallback: If no valid role is found in UserData, or UserData is null
                  // This means either _fetchUserData returned null, or the role claim was missing/invalid.
                  // Sign out the user and redirect to role selection.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FirebaseAuth.instance.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่พบประเภทบัญชีของคุณ โปรดเข้าสู่ระบบใหม่')),
                    );
                  });
                  return const RoleSelectPage(); // Show role selection after logout
                }
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
