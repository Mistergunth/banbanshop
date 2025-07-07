// lib/screens/seller/store_profile.dart (ฉบับแก้ไข)

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/post_model.dart';
import 'package:banbanshop/screens/seller/edit_store_screen.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class StoreProfileScreen extends StatefulWidget {
  final String storeId;
  final bool isSellerView;

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

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );

  @override
  void initState() {
    super.initState();
    _fetchStoreDataAndPosts();
  }

  Future<void> _launchMapsUrl(double lat, double lon) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดแอปแผนที่ได้')),
        );
      }
    }
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

      DocumentSnapshot storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .get();

      if (storeDoc.exists && storeDoc.data() != null) {
        setState(() {
          _store = Store.fromFirestore(storeDoc);
        });

        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('storeId', isEqualTo: widget.storeId)
            .orderBy('created_at', descending: true)
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

  Future<void> _deletePost(Post post) async {
    // แสดง AlertDialog เพื่อยืนยันการลบ
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

    if (confirmDelete != true) return;

    try {
      // 1. ลบโพสต์ออกจาก Firestore
      await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();

      // 2. ลบรูปภาพออกจาก Cloudinary (ถ้ามี)
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
        // ... (โค้ดลบรูปจาก Cloudinary)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโพสต์สำเร็จ!')),
        );
        // โหลดข้อมูลใหม่หลังจากลบ
        _fetchStoreDataAndPosts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการลบโพสต์: $e')),
        );
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditStoreScreen(store: _store!),
                  ),
                ).then((_) => _fetchStoreDataAndPosts());
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _store == null
                  ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
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
                                      : const AssetImage('assets/images/default_store.png') as ImageProvider,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_store!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(_store!.description, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text(_store!.locationAddress, style: TextStyle(color: Colors.grey[600]))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.category, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text(_store!.type, style: TextStyle(color: Colors.grey[600]))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text(_store!.openingHours, style: TextStyle(color: Colors.grey[600]))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Flexible(child: Text(_store!.phoneNumber, style: TextStyle(color: Colors.grey[600]))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ปุ่มนำทาง
                          if (_store?.latitude != null && _store?.longitude != null)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.navigation_outlined),
                                label: const Text('นำทางไปยังร้านค้า'),
                                onPressed: () {
                                  _launchMapsUrl(_store!.latitude!, _store!.longitude!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5C6BC0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                          Text(
                            widget.isSellerView ? 'โพสต์ของร้านค้าฉัน' : 'โพสต์ของร้าน ${_store!.name}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          _storePosts.isEmpty
                              ? const Center(child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 32.0),
                                child: Text('ยังไม่มีโพสต์สำหรับร้านค้านี้'),
                              ))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
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
    _updateTimeAgo();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeAgo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    } else {
      return '${(difference.inDays / 7).floor()} สัปดาห์ที่แล้ว';
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
