// lib/screens/buyer/buyer_profile_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';
import 'package:banbanshop/screens/auth/buyer_register_screen.dart';
import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/buyer/favorites_screen.dart';
import 'package:banbanshop/screens/buyer/shipping_address_screen.dart';
import 'package:banbanshop/screens/buyer/edit_buyer_profile_screen.dart';
import 'package:banbanshop/screens/buyer/buyer_orders_screen.dart';
import 'package:banbanshop/screens/buyer/ai_chatbot_screen.dart';


class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  User? _currentUser;
  BuyerProfile? _buyerProfile;
  bool _isLoading = true;

  // Cloudinary configuration
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  @override
  void initState() {
    super.initState();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = true; // Set loading to true when auth state changes
        });
        if (_currentUser != null) {
          _fetchBuyerProfile(); // Fetch profile if user is logged in
        } else {
          setState(() {
            _isLoading = false;
            _buyerProfile = null; // Clear profile if no user
          });
        }
      }
    });

    // Initial check for current user
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchBuyerProfile();
    } else {
      _isLoading = false;
    }
  }

  // Function to fetch buyer profile data from Firestore
  Future<void> _fetchBuyerProfile() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        if (mounted) {
          setState(() {
            _buyerProfile = BuyerProfile.fromFirestore(doc); // Update buyer profile
          });
        }
      } else {
        // Create a new profile if it doesn't exist
        final newProfile = BuyerProfile(
          uid: _currentUser!.uid,
          email: _currentUser!.email ?? '',
          fullName: _currentUser!.displayName,
          phoneNumber: _currentUser!.phoneNumber,
          shippingAddress: null,
          profileImageUrl: null,
        );
        await FirebaseFirestore.instance.collection('buyers').doc(_currentUser!.uid).set(newProfile.toFirestore());
        if (mounted) {
          setState(() {
            _buyerProfile = newProfile;
          });
        }
      }
    } catch (e) {
      print("Error fetching buyer profile: $e"); // Log errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูลโปรไฟล์: $e')),
        );
        setState(() {
          _buyerProfile = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Function to pick and upload a profile image
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return; // Return if no image was picked

    File imageFile = File(pickedFile.path);
    User? currentUser = _currentUser;

    if (currentUser == null) return; // Return if no user is logged in

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload image to Cloudinary
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: imageFile.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'buyer_profile_pictures', // Folder in Cloudinary
          uploadPreset: uploadPreset, // Upload preset
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        String downloadUrl = response.secureUrl!;
        // Update profile image URL in Firestore
        await FirebaseFirestore.instance
            .collection('buyers')
            .doc(currentUser.uid)
            .update({'profileImageUrl': downloadUrl});

        if (mounted) {
          Navigator.pop(context); // Dismiss loading indicator
          setState(() {
            _buyerProfile = _buyerProfile?.copyWith(profileImageUrl: downloadUrl); // Update profile locally
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตรูปโปรไฟล์สำเร็จ!')), // Show success message
          );
        }
      } else {
        throw Exception(response.error ?? 'Cloudinary upload failed'); // Handle Cloudinary errors
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Set loading to false
      }
    }
  }

  // Function to log out the user
  void _logout() async {
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))), // Blue loading
      );
    }

    if (_currentUser != null && _buyerProfile != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Lighter background color
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(), // Build the profile header section
              const SizedBox(height: 20), // Spacing below header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Action button for AI Chatbot
                    _buildProfileOptionButton(
                      icon: Icons.support_agent_outlined,
                      text: 'AI Chatbot ผู้ช่วยส่วนตัว',
                      color: const Color(0xFF0288D1), // Blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AiChatBotScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15), // Spacing
                    // Action button for buyer orders
                    _buildProfileOptionButton(
                      icon: Icons.receipt_long_outlined,
                      text: 'รายการสั่งซื้อของฉัน',
                      color: const Color(0xFF4A00E0), // Dark Purple
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BuyerOrdersScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15), // Spacing
                    // Action button for shipping address
                    _buildProfileOptionButton(
                      icon: Icons.location_on_outlined,
                      text: 'ที่อยู่จัดส่ง',
                      color: const Color(0xFF0288D1), // Blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShippingAddressScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15), // Spacing
                    // Action button for favorites
                    _buildProfileOptionButton(
                      icon: Icons.favorite_border,
                      text: 'รายการโปรด',
                      color: const Color(0xFF4A00E0), // Dark Purple
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 15), // Spacing
                    // Action button for editing profile
                    _buildProfileOptionButton(
                      icon: Icons.edit_outlined,
                      text: 'แก้ไขโปรไฟล์',
                      color: const Color(0xFF0288D1), // Blue
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBuyerProfileScreen(
                              buyerProfile: _buyerProfile!,
                              onProfileUpdated: _fetchBuyerProfile, // Pass refresh callback
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30), // Spacing before logout
                    // Logout button
                    _buildLogoutButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Screen for non-logged in users
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8), // Lighter background color
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400), // Neutral grey for non-logged in state
                const SizedBox(height: 16),
                const Text(
                  'เข้าสู่ระบบหรือสมัครสมาชิก',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), // Dark text
                ),
                const SizedBox(height: 8),
                Text(
                  'เพื่อดูประวัติการสั่งซื้อและจัดการโปรไฟล์ของคุณ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                // Login button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF0288D1), // Blue for login button
                    foregroundColor: Colors.white, // White text
                    elevation: 5, // Add elevation
                    shadowColor: const Color(0xFF0288D1).withOpacity(0.3), // Shadow color
                  ),
                  child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerRegisterScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF4A00E0), width: 2), // Dark Purple border
                    foregroundColor: const Color(0xFF4A00E0), // Dark Purple text
                    elevation: 0, // No elevation for outlined button
                  ),
                  child: const Text('สมัครสมาชิก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // Widget to build the profile header section
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient( // Blue to Dark Purple gradient
          colors: [Color(0xFF0288D1), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), // Rounded corners
          bottomRight: Radius.circular(30), // Rounded corners
        ),
        boxShadow: [ // Subtle shadow
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 0,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Stack( // Stack to overlay camera icon on avatar
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 55, // Slightly larger avatar border
                  backgroundColor: Colors.white, // White border effect
                  child: CircleAvatar(
                    radius: 50, // Avatar size
                    backgroundColor: const Color(0xFFE0F7FA), // Light blue background for avatar
                    backgroundImage: (_buyerProfile?.profileImageUrl != null && _buyerProfile!.profileImageUrl!.startsWith('http'))
                        ? NetworkImage(_buyerProfile!.profileImageUrl!) // Network image if URL is valid
                        : null, // No background image if using default icon
                    child: (_buyerProfile?.profileImageUrl == null || !_buyerProfile!.profileImageUrl!.startsWith('http'))
                        ? Icon(Icons.person, size: 60, color: const Color(0xFF0288D1)) // Blue color for default avatar icon
                        : null, // No child if an image is loaded
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A00E0), // Dark Purple for camera icon background
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2), // White border for camera icon
                    ),
                    child: const Icon(Icons.camera_alt, size: 24, color: Colors.white), // Camera icon
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15), // Spacing below avatar
          Text(
            _buyerProfile?.fullName ?? _currentUser?.displayName ?? _currentUser?.email ?? 'ผู้ซื้อ',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // White text for name
          ),
          const SizedBox(height: 5),
          Text(
            _buyerProfile?.email ?? _currentUser?.email ?? '',
            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)), // Lighter white for email
          ),
          if (_buyerProfile?.phoneNumber != null && _buyerProfile!.phoneNumber!.isNotEmpty)
            Text(
              _buyerProfile!.phoneNumber!,
              style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)), // Lighter white for phone number
            ),
        ],
      ),
    );
  }

  // Widget to build a generic profile option button
  Widget _buildProfileOptionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.grey, // Default color for icons
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Increased vertical padding
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Increased padding
          decoration: BoxDecoration(
            color: Colors.white, // White background
            borderRadius: BorderRadius.circular(15), // More rounded corners
            boxShadow: [ // Shadow for lifted effect
              BoxShadow(
                color: Colors.grey.withOpacity(0.1), // Subtle shadow
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out icon/text and arrow
            children: [
              Row( // Group icon and text
                children: [
                  Icon(icon, color: color), // Dynamic icon color
                  const SizedBox(width: 15), // Spacing
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18), // Grey arrow icon
            ],
          ),
        ),
      ),
    );
  }

  // Widget to build the logout button
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent, // Bright red for logout (standard warning color)
          borderRadius: BorderRadius.circular(15), // Consistent rounding
          boxShadow: [ // Shadow for lifted effect
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out icon/text and arrow
          children: [
            Row( // Group icon and text
              children: [
                Icon(Icons.logout, color: Colors.white), // White icon for contrast
                SizedBox(width: 15), // Spacing between icon and text
                Text(
                  'ออกจากระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for contrast
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18), // White arrow icon
          ],
        ),
      ),
    );
  }
}
