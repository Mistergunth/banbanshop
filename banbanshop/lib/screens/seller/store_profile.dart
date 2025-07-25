// lib/screens/seller/store_profile.dart

// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:banbanshop/screens/seller/edit_store_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/models/post_model.dart';
import 'package:banbanshop/screens/models/product_model.dart';
import 'package:banbanshop/screens/seller/add_edit_product_screen.dart';
import 'package:banbanshop/screens/buyer/product_detail_screen.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:banbanshop/screens/reviews/store_reviews_screen.dart';
import 'package:intl/intl.dart';


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
  List<Product> _storeProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool _isFavorited = false;
  bool _isCheckingFavorite = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchStoreData();
  }

  Future<void> _checkIfFavorited() async {
    if (_currentUser == null || widget.isSellerView) {
      if (mounted) setState(() => _isCheckingFavorite = false);
      return;
    }
    try {
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(_currentUser!.uid)
          .collection('favorites')
          .doc(widget.storeId)
          .get();
      if (mounted) {
        setState(() {
          _isFavorited = favoriteDoc.exists;
          _isCheckingFavorite = false;
        });
      }
    } catch (e) {
      print("Error checking favorite status: $e");
      if (mounted) {
        setState(() => _isCheckingFavorite = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อเพิ่มร้านค้าในรายการโปรด')),
      );
      return;
    }
    if (_isCheckingFavorite) return;

    setState(() => _isCheckingFavorite = true);

    final favoriteRef = FirebaseFirestore.instance
        .collection('buyers')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .doc(widget.storeId);

    try {
      if (_isFavorited) {
        await favoriteRef.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบออกจากรายการโปรดแล้ว')),
          );
        }
      } else {
        await favoriteRef.set({
          'storeId': widget.storeId,
          'storeName': _store?.name,
          'imageUrl': _store?.imageUrl,
          'addedAt': Timestamp.now(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เพิ่มในรายการโปรดแล้ว')),
          );
        }
      }
      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาด')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingFavorite = false);
      }
    }
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

  Future<void> _fetchStoreData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.storeId.isEmpty) {
        throw Exception('Store ID is empty.');
      }

      final storeFuture = FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
      
      final postsFuture = FirebaseFirestore.instance
          .collection('posts')
          .where('storeId', isEqualTo: widget.storeId)
          .orderBy('created_at', descending: true) 
          .get();
          
      final productsFuture = FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products')
          .orderBy('createdAt', descending: false)
          .get();

      final results = await Future.wait([storeFuture, postsFuture, productsFuture]);
      
      final storeDoc = results[0] as DocumentSnapshot;
      final postsSnapshot = results[1] as QuerySnapshot;
      final productsSnapshot = results[2] as QuerySnapshot;


      if (storeDoc.exists && storeDoc.data() != null) {
        final fetchedStore = Store.fromFirestore(storeDoc);
        final fetchedPosts = postsSnapshot.docs.map((doc) => Post.fromJson({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList();
        
        List<Product> fetchedProducts;
        if (widget.isSellerView) {
          fetchedProducts = productsSnapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        } else {
          fetchedProducts = productsSnapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where((product) => product.isAvailable)
              .toList();
        }

        if(mounted) {
          setState(() {
            _store = fetchedStore;
            _storePosts = fetchedPosts;
            _storeProducts = fetchedProducts;
          });
        }
        await _checkIfFavorited();
      } else {
        if(mounted) {
          setState(() {
            _errorMessage = 'ไม่พบข้อมูลร้านค้าสำหรับ ID: ${widget.storeId}';
          });
        }
      }
    } catch (e) {
      print("Error fetching store data: $e");
      if(mounted) {
        setState(() {
          _errorMessage = 'เกิดข้อผิดพลาด: $e';
        });
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        try {
            await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ลบโพสต์สำเร็จ!')),
                );
                _fetchStoreData();
            }
        } catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เกิดข้อผิดพลาดในการลบโพสต์: $e')),
                );
            }
        }
    }
  }


  Widget _buildStoreStatus(Store store) {
    final bool isOpen = store.isOpen;
    final String statusText = isOpen ? 'เปิด' : 'ปิด';
    final Color statusColor = isOpen ? Colors.green : Colors.red;

    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final String currentDayKey = DateFormat('E').format(now).toLowerCase().substring(0, 3);
    final todaySchedule = store.operatingHours[currentDayKey];
    String hoursText = 'ปิดทำการวันนี้';
    if (todaySchedule != null && todaySchedule['isOpen'] == true) {
      hoursText = 'วันนี้: ${todaySchedule['opens']} - ${todaySchedule['closes']}';
    }
    if (store.isManuallyClosed) {
      hoursText = 'ร้านปิดชั่วคราว';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                statusText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hoursText,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProductSection() {
    if (_storeProducts.isEmpty) {
      if(widget.isSellerView){
         return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('ยังไม่มีสินค้าในร้านค้าของคุณ\nกดปุ่ม + เพื่อเพิ่มสินค้าใหม่', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
         );
      }
      return const SizedBox.shrink(); 
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สินค้าของร้าน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _storeProducts.length,
              itemBuilder: (context, index) {
                final product = _storeProducts[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        if (widget.isSellerView) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditProductScreen(
                storeId: widget.storeId,
                product: product,
              ),
            ),
          ).then((result) {
            if (result == true) {
              _fetchStoreData();
            }
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Opacity(
          opacity: widget.isSellerView && !product.isAvailable ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl == null || product.imageUrl!.isEmpty
                    ? const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40))
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '฿${product.price.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
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
                ).then((value) {
                  if (value == true) {
                    _fetchStoreData();
                  }
                });
              },
            ),
        ],
      ),
      floatingActionButton: widget.isSellerView
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditProductScreen(storeId: widget.storeId),
                  ),
                ).then((result) {
                  if (result == true) {
                    _fetchStoreData();
                  }
                });
              },
              backgroundColor: const Color(0xFF9C6ADE),
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _store == null
                  ? const Center(child: Text('ไม่พบข้อมูลร้านค้า'))
                  : RefreshIndicator(
                      onRefresh: _fetchStoreData,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                        const SizedBox(height: 4),
                                        if (_store!.reviewCount > 0)
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 20),
                                              const SizedBox(width: 4),
                                              Text(
                                                _store!.averageRating.toStringAsFixed(1),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '(${_store!.reviewCount} รีวิว)',
                                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            'ยังไม่มีรีวิว',
                                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                          ),
                                        const SizedBox(height: 8),
                                        _buildStoreStatus(_store!),
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
                            Column(
                              children: [
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
                                const SizedBox(height: 8),
                                if (!widget.isSellerView)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: _isCheckingFavorite
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                                          : Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
                                      label: Text(_isFavorited ? 'ลบจากรายการโปรด' : 'เพิ่มในรายการโปรด'),
                                      onPressed: _toggleFavorite,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFavorited ? Colors.pink[400] : const Color(0xFF7E57C2),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.rate_review_outlined),
                                    label: const Text('เรตติ้งและรีวิว'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoreReviewsScreen(
                                            storeId: widget.storeId,
                                            storeName: _store?.name ?? 'ร้านค้า',
                                            isSellerView: widget.isSellerView,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF66BB6A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildProductSection(),
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

    if (difference.inSeconds < 60) return 'เมื่อสักครู่';
    if (difference.inMinutes < 60) return '${difference.inMinutes} นาทีที่แล้ว';
    if (difference.inHours < 24) return '${difference.inHours} ชั่วโมงที่แล้ว';
    if (difference.inDays < 7) return '${difference.inDays} วันที่แล้ว';
    return '${(difference.inDays / 7).floor()} สัปดาห์ที่แล้ว';
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
                    const SnackBar(content: Text('ฟังก์ชันสั่งเลยยังไม่พร้อมใช้งานในหน้านี้')),
                  );
                }),
                const SizedBox(width: 10),
                ActionButton(text: 'ดูหน้าร้าน', onTap: () {
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
