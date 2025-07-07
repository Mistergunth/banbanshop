// lib/screens/seller/store_profile.dart

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/store_model.dart'; // <--- Use Store model from this file instead
import 'package:banbanshop/screens/post_model.dart'; // Import Post model
import 'package:banbanshop/screens/create_post.dart'; // Import CreatePostScreen
import 'package:banbanshop/screens/seller/edit_store_screen.dart'; // Import EditStoreScreen
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // Import Cloudinary SDK
import 'dart:async'; // <--- Add IMPORT for Timer


class StoreProfileScreen extends StatefulWidget {
  final String storeId;
  final bool isSellerView; // true if owner is viewing, false if buyer/general public

  const StoreProfileScreen({
    super.key,
    required this.storeId,
    this.isSellerView = false,
  });

  @override
  _StoreProfileScreenState createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  Store? _store;
  List<Post> _storePosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Define your Cloudinary credentials here (for image deletion)
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- Replace with your Cloud Name
    apiKey: '157343641351425', // <-- Required for Signed Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- Required for Signed Deletion
  );

  @override
  void initState() {
    super.initState();
    _fetchStoreDataAndPosts();
  }

  Future<void> _fetchStoreDataAndPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.storeId.isEmpty) {
        throw Exception('Store ID is empty.');
      }

      // Fetch store data
      DocumentSnapshot storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (storeDoc.exists && storeDoc.data() != null) {
        // Use Store.fromFirestore() as defined in store_create.dart
        setState(() {
          _store = Store.fromFirestore(storeDoc);
        });

        // Fetch posts related to this store
        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('storeId', isEqualTo: widget.storeId)
            .orderBy('created_at', descending: true) // Add orderBy
            .get();

        final fetchedPosts = postsSnapshot.docs.map((doc) {
          return Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id});
        }).toList();

        setState(() {
          _storePosts = fetchedPosts;
        });
      } else {
        setState(() {
          _errorMessage = 'ไม่พบข้อมูลร้านค้าสำหรับ ID: ${widget.storeId}';
        });
      }
    } on FirebaseException catch (e) {
      print("Firebase Error fetching store data or posts: ${e.code} - ${e.message}");
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดจาก Firebase: ${e.message}';
      });
    } catch (e) {
      print("Error fetching store data or posts: $e");
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to delete a post in the store page
  Future<void> _deletePost(Post post) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        // 1. Delete post from Firestore
        await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();

        // 2. Delete image from Cloudinary
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          try {
            final uri = Uri.parse(post.imageUrl!);
            final pathSegments = uri.pathSegments;
            String publicId = pathSegments.last.split('.').first;
            if (pathSegments.length > 2) {
              publicId = '${pathSegments[pathSegments.length - 2]}/${pathSegments.last.split('.').first}';
            }

            final deleteResponse = await cloudinary.deleteResource(publicId: publicId);

            if (!deleteResponse.isSuccessful) {
              print('Failed to delete image from Cloudinary: ${deleteResponse.error}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ลบรูปภาพจาก Cloudinary ไม่สำเร็จ: ${deleteResponse.error}')),
                );
              }
            }
          } catch (e) {
            print('Error deleting image from Cloudinary: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรูปภาพ: $e')),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบโพสต์สำเร็จ!')),
          );
        }
        // Reload store data and posts after successful deletion
        _fetchStoreDataAndPosts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบโพสต์: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSellerView ? 'จัดการร้านค้าของฉัน' : _store?.name ?? 'หน้าร้านค้า'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isSellerView && _store != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to Edit Store Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditStoreScreen(store: _store!),
                  ),
                ).then((_) => _fetchStoreDataAndPosts()); // Reload after editing store
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _fetchStoreDataAndPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C6ADE),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              : _store == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_mall_directory_outlined, color: Colors.grey, size: 60),
                          const SizedBox(height: 20),
                          const Text(
                            'ไม่พบข้อมูลร้านค้า',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          if (widget.isSellerView)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const StoreCreateScreen()),
                                ).then((_) => _fetchStoreDataAndPosts()); // Reload after creating store
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9C6ADE),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('สร้างร้านค้าใหม่'),
                            ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _store!.imageUrl != null && _store!.imageUrl!.startsWith('http')
                                      ? NetworkImage(_store!.imageUrl!)
                                      : const AssetImage('assets/images/default_store.png') as ImageProvider, // Fallback
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _store!.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _store!.description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // แก้ไข: แยกแต่ละข้อมูลลงใน Row ของตัวเอง
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line text
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _store!.locationAddress,
                                              style: TextStyle(color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 5, // Allow more lines for address
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4), // Add spacing between rows
                                      Row(
                                        children: [
                                          Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _store!.type,
                                              style: TextStyle(color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _store!.openingHours,
                                              style: TextStyle(color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _store!.phoneNumber,
                                              style: TextStyle(color: Colors.grey[600]),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.isSellerView ? 'โพสต์ของร้านค้าฉัน' : 'โพสต์ของร้าน ${_store!.name}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _storePosts.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'ยังไม่มีโพสต์สำหรับร้านค้านี้',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                      if (widget.isSellerView) ...[
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (_store != null && _store!.ownerUid == FirebaseAuth.instance.currentUser?.uid) {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => CreatePostScreen(
                                                    shopName: _store!.name,
                                                    storeId: _store!.id,
                                                  ),
                                                ),
                                              );
                                              _fetchStoreDataAndPosts(); // Reload posts after creating a new one
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('คุณไม่มีสิทธิ์สร้างโพสต์สำหรับร้านค้านี้')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF9C6ADE),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('สร้างโพสต์ใหม่'),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true, // Make ListView take only necessary space
                                  physics: const NeverScrollableScrollPhysics(), // Disable inner ListView scrolling
                                  itemCount: _storePosts.length,
                                  itemBuilder: (context, index) {
                                    final post = _storePosts[index];
                                    return PostCard(
                                      post: post,
                                      onDelete: _deletePost,
                                      currentUserId: FirebaseAuth.instance.currentUser?.uid,
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
    );
  }
}

// PostCard Widget (Copied from feed_page.dart to make it work independently)
// If you already have PostCard in a separate file (e.g., widgets/post_card.dart)
// you should import it instead of copying the code
// But for the completeness of this file, I will put it here
class PostCard extends StatefulWidget {
  final Post post;
  final Function(Post) onDelete;
  final String? currentUserId;

  const PostCard({
    super.key,
    required this.post,
    required this.onDelete,
    this.currentUserId,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late String _timeAgoString;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimeAgo(); // Calculate time for the first time
    // Set Timer to update every 1 minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeAgo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel Timer when Widget is disposed
    super.dispose();
  }

  void _updateTimeAgo() {
    if (mounted) {
      setState(() {
        _timeAgoString = _formatTimeAgo(widget.post.createdAt);
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).ceil();
      return '$weeks สัปดาห์ที่แล้ว';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).ceil();
      return '$months เดือนที่แล้ว';
    } else {
      final years = (difference.inDays / 365).ceil();
      return '$years ปีที่แล้ว';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = widget.currentUserId != null && widget.currentUserId == widget.post.ownerUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.post.avatarImageUrl != null && widget.post.avatarImageUrl!.startsWith('http')
                      ? NetworkImage(widget.post.avatarImageUrl!)
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _timeAgoString,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C6ADE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${widget.post.category} | ${widget.post.province}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onDelete(widget.post),
                  ),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Image
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(widget.post.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              ),
            ),

          const SizedBox(height: 15),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                ActionButton(text: 'สั่งเลย', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ฟังก์ชันสั่งเลยยังไม่พร้อมใช้งาน')),
                  );
                }),
                const SizedBox(width: 10),
                ActionButton(text: 'ดูหน้าร้าน', onTap: () {
                  if (widget.post.storeId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreProfileScreen(
                          storeId: widget.post.storeId,
                          isSellerView: false,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไม่พบ ID ร้านค้าสำหรับโพสต์นี้')),
                    );
                  }
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C6ADE),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
