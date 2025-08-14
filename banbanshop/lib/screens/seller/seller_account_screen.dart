// lib/screens/seller/seller_account_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/seller/seller_order_screen.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/reviews/store_reviews_screen.dart';
import 'package:banbanshop/screens/seller/edit_seller_profile_screen.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/product_management_screen.dart';
import 'package:banbanshop/screens/seller/edit_payment_screen.dart';


class SellerAccountScreen extends StatefulWidget {
  final SellerProfile? sellerProfile;
  final VoidCallback? onRefresh;

  const SellerAccountScreen({
    super.key,
    this.sellerProfile,
    this.onRefresh,
  });

  @override
  State<SellerAccountScreen> createState() => _SellerAccountScreenState();
}

class _SellerAccountScreenState extends State<SellerAccountScreen> {
  Store? _store;
  bool _isStoreLoading = true;

  // Cloudinary configuration
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );
  
  @override
  void initState() {
    super.initState();
    // Fetch store data if the seller has a store
    if (widget.sellerProfile?.hasStore == true && widget.sellerProfile?.storeId != null) {
      _fetchStoreData();
    } else {
      _isStoreLoading = false; // No store, so no loading needed
    }
  }
  
  // Function to fetch store data from Firestore
  Future<void> _fetchStoreData() async {
    if (!mounted) return; // Check if the widget is still mounted
    setState(() => _isStoreLoading = true); // Set loading state to true
    try {
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.sellerProfile!.storeId!)
          .get();
      if (storeDoc.exists) {
        if (mounted) {
          setState(() {
            _store = Store.fromFirestore(storeDoc); // Update store data
          });
        }
      }
    } catch (e) {
      print("Error fetching store data: $e"); // Log any errors
    } finally {
      if (mounted) {
        setState(() => _isStoreLoading = false);
      }
    }
  }
  
  // Function to toggle the store's manual open/close status
  Future<void> _toggleManualStoreStatus(bool isOpen) async {
    if (_store == null) return; // Return if store data is not available
    
    final bool isManuallyClosed = !isOpen; // Determine the new status
    
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(_store!.id)
          .update({'isManuallyClosed': isManuallyClosed}); // Update Firestore
          
      if (mounted) {
        setState(() {
          // Create a new Store object with the updated status
          _store = Store(
            id: _store!.id,
            ownerUid: _store!.ownerUid,
            name: _store!.name,
            description: _store!.description,
            type: _store!.type,
            category: _store!.category,
            imageUrl: _store!.imageUrl,
            locationAddress: _store!.locationAddress,
            latitude: _store!.latitude,
            longitude: _store!.longitude,
            phoneNumber: _store!.phoneNumber,
            createdAt: _store!.createdAt,
            province: _store!.province,
            averageRating: _store!.averageRating,
            reviewCount: _store!.reviewCount,
            isManuallyClosed: isManuallyClosed, // Update the status here
            operatingHours: _store!.operatingHours,
            paymentInfo: _store!.paymentInfo,
          );
        });
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isManuallyClosed ? 'ร้านค้าปิดชั่วคราวแล้ว' : 'ร้านค้าเปิดให้บริการแล้ว')),
        );
      }
    } catch (e) {
      // Show an error message if update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสถานะ: $e')),
      );
    }
  }

  // Function to pick and upload a profile image
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // Return if no image was picked

    File imageFile = File(pickedFile.path);
    User? currentUser = FirebaseAuth.instance.currentUser;

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
          folder: 'profile_pictures', // Folder in Cloudinary
          uploadPreset: 'flutter_unsigned_upload', // Upload preset
        ),
      );

      if (response.isSuccessful && response.secureUrl != null) {
        String downloadUrl = response.secureUrl!;
        // Update profile image URL in Firestore
        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(currentUser.uid)
            .update({'profileImageUrl': downloadUrl});

        if (mounted) {
          Navigator.pop(context); // Dismiss loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตโปรไฟล์สำเร็จ!')), // Show success message
          );
          widget.onRefresh?.call(); // Call refresh callback
        }
      } else {
        throw Exception(response.error ?? 'Unknown Cloudinary error'); // Handle Cloudinary errors
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')),
        );
      }
    }
  }

  // Function to log out the seller
  void _logoutSeller() async {
    await FirebaseAuth.instance.signOut(); // Sign out from Firebase
  }

  // Function to navigate to store creation screen and refresh
  void _navigateAndRefreshOnStoreCreation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreCreateScreen(
          onRefresh: widget.onRefresh, // Pass refresh callback
        ),
      ),
    );
    // After returning from StoreCreateScreen, refresh store data
    if (widget.sellerProfile?.hasStore == true && widget.sellerProfile?.storeId != null) {
      _fetchStoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sellerProfile == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))); // Blue loading indicator
    }

    final seller = widget.sellerProfile!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header section for profile information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30), // Increased vertical padding
            decoration: const BoxDecoration(
              gradient: LinearGradient( // Blue to Dark Purple gradient
                colors: [Color(0xFF0288D1), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30), // More rounded corners
                bottomRight: Radius.circular(30), // More rounded corners
              ),
              boxShadow: [ // Subtle shadow for depth
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
                          backgroundImage: (seller.profileImageUrl != null && seller.profileImageUrl!.startsWith('http'))
                              ? NetworkImage(seller.profileImageUrl!) // Network image if URL is valid
                              : null, // No background image if using default icon
                          child: (seller.profileImageUrl == null || !seller.profileImageUrl!.startsWith('http'))
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
                  seller.fullName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), // White text for name
                ),
                const SizedBox(height: 5),
                Text(
                  seller.phoneNumber,
                  style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)), // Lighter white for phone number
                ),
                Text(
                  seller.email,
                  style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)), // Lighter white for email
                ),
              ],
            ),
          ),
          const SizedBox(height: 20), // Spacing below header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.person_outline,
                  text: 'แก้ไขโปรไฟล์',
                  color: Colors.white, // Blue
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSellerProfileScreen(
                          sellerProfile: seller,
                          onProfileUpdated: widget.onRefresh ?? () {},
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15), // Spacing between buttons

                // Conditional rendering for store-related actions
                if (seller.hasStore == true && seller.storeId != null)
                  Column(
                    children: [
                      if (_isStoreLoading)
                        const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
                      else if (_store != null)
                        // Card for store open/close switch
                        Card(
                          elevation: 4, // Increased elevation for depth
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Consistent rounding
                          margin: const EdgeInsets.symmetric(vertical: 8.0), // Add vertical margin
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Adjust content padding
                            title: Text(
                              !_store!.isManuallyClosed ? 'ร้านเปิดอยู่' : 'ร้านปิดชั่วคราว',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Slightly larger font for title
                                color: !_store!.isManuallyClosed ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                            subtitle: Text(
                              !_store!.isManuallyClosed ? 'ลูกค้าสามารถเห็นและสั่งซื้อได้' : 'ลูกค้าจะเห็นร้านค้าแต่ไม่สามารถสั่งซื้อได้',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600), // Adjusted font size and color for subtitle
                            ),
                            value: !_store!.isManuallyClosed,
                            onChanged: _toggleManualStoreStatus,
                            activeColor: Colors.green.shade600, // More vibrant active color
                            inactiveThumbColor: Colors.grey.shade400, // Better inactive color
                            inactiveTrackColor: Colors.grey.shade200, // Better inactive track color
                          ),
                        ),
                      const SizedBox(height: 15),

                      // Action button for store profile
                      _buildActionButton(
                        icon: Icons.store_outlined,
                        text: 'หน้าโปรไฟล์ร้านค้า',
                        color: Colors.white, // Dark Purple
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreProfileScreen(
                                storeId: seller.storeId!,
                                isSellerView: true,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Action button for viewing orders
                      _buildActionButton(
                        icon: Icons.receipt_long_outlined,
                        text: 'ดูออเดอร์',
                        color: Colors.white, // Blue
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SellerOrdersScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Action button for product management
                      _buildActionButton(
                        icon: Icons.inventory_2_outlined,
                        text: 'จัดการสินค้า',
                        color: Colors.white, // Dark Purple
                        onTap: () {
                          if (_store != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductManagementScreen(
                                  storeId: _store!.id,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กำลังโหลดข้อมูลร้านค้า กรุณาลองอีกครั้ง')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      // Action button for payment management
                      _buildActionButton(
                        icon: Icons.payment_outlined,
                        text: 'จัดการช่องทางชำระเงิน',
                        color: Colors.white, // Blue
                        onTap: () {
                          if (_store != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPaymentScreen(store: _store!),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _fetchStoreData();
                              }
                            });
                          } else {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กำลังโหลดข้อมูลร้านค้า กรุณาลองอีกครั้ง')),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      // Action button for ratings and reviews
                      _buildActionButton(
                        icon: Icons.star_border_outlined,
                        text: 'เรตติ้งและรีวิว',
                        color: Colors.white, // Dark Purple
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StoreReviewsScreen(
                                storeId: seller.storeId!,
                                storeName: _store?.name ?? 'ร้านค้าของคุณ',
                                isSellerView: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                else
                  // Action button for creating a store
                  _buildActionButton(
                    icon: Icons.add_business_outlined,
                    text: 'สร้างร้านค้า',
                    color: Colors.white, // Blue
                    onTap: _navigateAndRefreshOnStoreCreation,
                  ),

                const SizedBox(height: 30), // Spacing before logout button
                _buildLogoutButton(context), // Logout button
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build a generic action button
  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), // Increased padding
        decoration: BoxDecoration(
          color: color, // Background color of the button
          borderRadius: BorderRadius.circular(15), // More rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out icon/text and arrow
          children: [
            Row( // Group icon and text
              children: [
                Icon(icon, color: const Color(0xFF0288D1)), // White icon for contrast
                const SizedBox(width: 15), // Spacing between icon and text
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // White text for contrast
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18), // White arrow icon on the right
          ],
        ),
      ),
    );
  }

  // Widget to build the logout button
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: _logoutSeller,
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
