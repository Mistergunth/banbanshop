// lib/screens/feed_page.dart
// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, curly_braces_in_flow_control_structures, unused_field, unnecessary_non_null_assertion, unused_import, use_build_context_synchronously

import 'package:banbanshop/screens/seller/seller_order_screen.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:flutter/material.dart';
import 'package:banbanshop/widgets/bottom_navbar_widget.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/seller_account_screen.dart';
import 'package:banbanshop/screens/buyer/buyer_profile_screen.dart';
import 'package:banbanshop/screens/store_screen_content.dart';
import 'package:banbanshop/screens/models/create_post.dart';
import 'package:banbanshop/screens/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:banbanshop/screens/buyer/favorites_screen.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';
import 'package:banbanshop/screens/role_select.dart';
import 'package:banbanshop/screens/buyer/buyer_cart_screen.dart';
import 'package:banbanshop/screens/buyer/checkout_screen.dart';
import 'package:banbanshop/screens/models/cart_model.dart';


class FeedPage extends StatefulWidget {
  final String selectedProvince;
  final String selectedCategory;
  final SellerProfile? sellerProfile;
  final Store? storeProfile;
  final VoidCallback? onRefresh;
  final bool isSeller;

  const FeedPage({
    super.key,
    required this.selectedProvince,
    required this.selectedCategory,
    this.sellerProfile,
    this.storeProfile,
    this.onRefresh,
    this.isSeller = false,
  });

  @override
  _FeedPageState createState() => _FeedPageState();
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Increased padding
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0288D1) : Colors.white, // Deeper blue for selected, matching icon
          borderRadius: BorderRadius.circular(25), // More rounded corners
          boxShadow: [ // Subtle shadow
            BoxShadow(
              color: isSelected ? const Color.fromARGB(255, 19, 117, 255).withOpacity(0.4) : Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF0288D1), // Text color for selected/unselected, matching icon
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}


class _FeedPageState extends State<FeedPage> {
  final TextEditingController searchController = TextEditingController();
  String _selectedTopFilter = 'ฟีดโพสต์';
  int _selectedIndex = 0;
  String? _drawerSelectedProvince;
  String? _drawerSelectedCategory;

  final List<String> _provinces = [ 'ทั้งหมด', 'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก', 'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี', 'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์', 'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย', 'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย', 'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู', 'อ่างทอง', 'อุดรธานี', 'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ', ];
  final List<String> _categories = [ 'ทั้งหมด', 'OTOP', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'สิ่งของเครื่องใช้', ];

  List<Post> _allPosts = [];
  bool _isLoadingPosts = true;
  StreamSubscription? _postsSubscription;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _drawerSelectedProvince = widget.selectedProvince;
    _drawerSelectedCategory = widget.selectedCategory;

    if (widget.sellerProfile != null && (widget.selectedProvince == 'ทั้งหมด' || widget.selectedProvince.isEmpty)) {
      _drawerSelectedProvince = widget.sellerProfile!.province;
    }

    _fetchPostsFromFirestore();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  void _fetchPostsFromFirestore() {
    _postsSubscription?.cancel();
    setState(() {
      _isLoadingPosts = true;
      _allPosts = [];
    });

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('posts');

    if (_drawerSelectedProvince != 'ทั้งหมด' && _drawerSelectedProvince != null) {
      query = query.where('province', isEqualTo: _drawerSelectedProvince);
    }
    if (_drawerSelectedCategory != 'ทั้งหมด' && _drawerSelectedCategory != null) {
      query = query.where('product_category', isEqualTo: _drawerSelectedCategory);
    }

    query = query.orderBy('created_at', descending: true);

    _postsSubscription = query.snapshots().listen((snapshot) {
      if (!mounted) return;
      final fetchedPosts = snapshot.docs.map((doc) {
        return Post.fromJson({...doc.data(), 'id': doc.id});
      }).toList();

      setState(() {
        _allPosts = fetchedPosts;
        _isLoadingPosts = false;
      });
    }, onError: (error) {
      if (!mounted) return;
      print("Error fetching posts: $error");
      setState(() {
        _isLoadingPosts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงโพสต์: $error')),
      );
    });
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
      setState(() => _isLoadingPosts = true);
      try {
        await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          // Cloudinary deletion logic...
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบโพสต์สำเร็จ!')),
          );
        }
      } catch (e) {
        // Error handling...
      } finally {
        if (mounted) {
          setState(() => _isLoadingPosts = false);
        }
      }
    }
  }

  void _navigateToCreatePost() {
    if (widget.sellerProfile != null && widget.storeProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(
            shopName: widget.storeProfile!.name,
            storeId: widget.storeProfile!.id,
          ),
        ),
      ).then((_) {
        _fetchPostsFromFirestore();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อมูลร้านค้าไม่สมบูรณ์ กรุณาลองเข้าสู่ระบบใหม่')),
      );
    }
  }

  void _onItemTapped(int index) async {
    if (index == 2) {
      if (widget.isSeller) {
        if (widget.sellerProfile != null && widget.storeProfile != null) {
          _navigateToCreatePost();
        } else if (widget.sellerProfile != null && widget.storeProfile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('คุณต้องสร้างร้านค้าก่อนจึงจะสร้างโพสต์ได้')),
          );
          Navigator.push(context, MaterialPageRoute(builder: (context) => StoreCreateScreen(onRefresh: widget.onRefresh)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เฉพาะผู้ขายเท่านั้นที่สามารถสร้างโพสต์ได้')),
        );
      }
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMiddlePage() {
    return widget.isSeller
        ? const SellerOrdersScreen(isEmbedded: true)
        : const BuyerCartScreen();
  }

  Widget _buildProfilePage() {
    if (widget.isSeller) {
      return SellerAccountScreen(
        sellerProfile: widget.sellerProfile,
        onRefresh: widget.onRefresh,
      );
    } else {
      return const BuyerProfileScreen();
    }
  }

  List<Post> get filteredPosts {
    final filteredByProvinceAndCategory = _allPosts.where((post) {
      final matchesProvince = _drawerSelectedProvince == 'ทั้งหมด' || post.province == _drawerSelectedProvince;
      final matchesCategory = _drawerSelectedCategory == 'ทั้งหมด' || post.productCategory == _drawerSelectedCategory;
      return matchesProvince && matchesCategory;
    }).toList();

    if (searchController.text.isEmpty) {
      return filteredByProvinceAndCategory;
    } else {
      final query = searchController.text.toLowerCase();
      return filteredByProvinceAndCategory.where((post) {
        return post.title.toLowerCase().contains(query) ||
            post.shopName.toLowerCase().contains(query) ||
            post.category.toLowerCase().contains(query) ||
            post.province.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildFeedContent(),
      _buildMiddlePage(),
      Container(), // Placeholder for Create Post
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Lighter background color
      appBar: AppBar(
        flexibleSpace: Container( // Added flexibleSpace for gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple to dark purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20, color: Colors.white), // White icon color
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // White text color
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (BuildContext innerContext) {
              return IconButton(
                icon: const Icon(Icons.menu, size: 24, color: Colors.white), // White icon color
                onPressed: () {
                  Scaffold.of(innerContext).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient( // Vibrant gradient for drawer header
                  colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Purple to dark purple
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.storeProfile?.name ?? widget.sellerProfile?.fullName ?? 'ผู้ใช้บ้านบ้านช็อป',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (widget.sellerProfile != null)
                      Text(
                        '${widget.sellerProfile!.province} | ${widget.sellerProfile!.email}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined, color: Colors.purple.shade700),
              title: const Text('หน้าแรก (ฟีดโพสต์)'),
              onTap: () {
                _onItemTapped(0);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.storefront_outlined, color: Colors.deepOrange.shade700),
              title: const Text('ร้านค้าทั้งหมด'),
              onTap: () {
                setState(() {
                  _selectedTopFilter = 'ร้านค้า';
                  _selectedIndex = 0;
                });
                if (mounted) Navigator.pop(context);
              },
            ),
            if (widget.storeProfile != null)
              ListTile(
                leading: Icon(Icons.settings_outlined, color: Colors.blue.shade700),
                title: const Text('จัดการร้านค้าของฉัน'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreProfileScreen(
                        storeId: widget.storeProfile!.id,
                        isSellerView: true,
                      ),
                    ),
                  );
                },
              ),
            if (!widget.isSeller)
              ListTile(
                leading: Icon(Icons.favorite_outline, color: Colors.pink.shade700),
                title: const Text('รายการโปรด'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _drawerSelectedProvince,
                decoration: InputDecoration(
                  labelText: 'เลือกจังหวัด',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _provinces.map((String province) {
                  return DropdownMenuItem<String>(
                    value: province,
                    child: Text(province),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _drawerSelectedProvince = newValue;
                    _fetchPostsFromFirestore();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _drawerSelectedCategory,
                decoration: InputDecoration(
                  labelText: 'เลือกหมวดหมู่',
                  labelStyle: TextStyle(color: Colors.grey[700]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _drawerSelectedCategory = newValue;
                    _fetchPostsFromFirestore();
                  });
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('ออกจากระบบ'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedIndex == 0)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      height: 50, // Slightly taller search bar
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25), // More rounded
                        boxShadow: [ // Subtle shadow
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหาโพสต์ หรือ ร้านค้า...', // More descriptive hint
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22), // Larger icon
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        ),
                        onChanged: (query) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 15), // Increased spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly
                      children: [
                        FilterButton(
                          text: 'ฟีดโพสต์',
                          isSelected: _selectedTopFilter == 'ฟีดโพสต์',
                          onTap: () {
                            setState(() {
                              _selectedTopFilter = 'ฟีดโพสต์';
                              _fetchPostsFromFirestore();
                            });
                          },
                        ),
                        FilterButton(
                          text: 'ร้านค้า',
                          isSelected: _selectedTopFilter == 'ร้านค้า',
                          onTap: () {
                            setState(() {
                              _selectedTopFilter = 'ร้านค้า';
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoadingPosts && _selectedTopFilter == 'ฟีดโพสต์'
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A))) // Darker purple loading
                  : IndexedStack(
                      index: _selectedIndex,
                      children: pages,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbarWidget(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        isSeller: widget.isSeller,
        hasStore: widget.storeProfile != null,
      ),
    );
  }

  Widget _buildFeedContent() {
    // Wrap the Container with ClipRRect to ensure content is clipped to rounded corners
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30), // More rounded
        topRight: Radius.circular(30), // More rounded
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          // Removed borderRadius from here as it's now handled by ClipRRect
          boxShadow: [ // Subtle shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5), // Shadow at the top
            ),
          ],
        ),
        child: _selectedTopFilter == 'ฟีดโพสต์'
            ? (filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 60, color: Colors.grey), // Changed icon
                        const SizedBox(height: 15),
                        const Text(
                          'ไม่พบโพสต์ที่ตรงกับเงื่อนไข',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${_drawerSelectedCategory ?? 'ทั้งหมด'} ใน ${_drawerSelectedProvince ?? 'ทั้งหมด'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon( // Added refresh button
                          onPressed: () {
                            searchController.clear();
                            _drawerSelectedProvince = 'ทั้งหมด';
                            _drawerSelectedCategory = 'ทั้งหมด';
                            _fetchPostsFromFirestore();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('รีเซ็ตการค้นหา', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A00E0), // Dark purple button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return PostCard(
                        post: post,
                        onDelete: _deletePost,
                        currentUserId: FirebaseAuth.instance.currentUser?.uid,
                        isSeller: widget.isSeller,
                      );
                    },
                  ))
            : StoreScreenContent(
                selectedProvince: _drawerSelectedProvince ?? 'ทั้งหมด',
                selectedCategory: _drawerSelectedCategory ?? 'ทั้งหมด',
              ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'บ้านบ้านช็อป';
      case 1:
        return widget.isSeller ? 'รายการออเดอร์' : 'ตะกร้าสินค้า';
      case 2:
        return 'สร้างโพสต์';
      case 3:
        return widget.isSeller ? 'บัญชีผู้ขาย' : 'โปรไฟล์ผู้ซื้อ';
      default:
        return 'บ้านบ้านช็อป';
    }
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  final Function(Post) onDelete;
  final String? currentUserId;
  final bool isSeller;

  const PostCard({
    super.key,
    required this.post,
    required this.onDelete,
    this.currentUserId,
    required this.isSeller,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late String _timeAgoString;
  Timer? _timer;
  bool _isProcessingOrder = false;

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

  Future<int?> _showQuantityDialog(BuildContext context) {
    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('เลือกจำนวนสินค้า'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), // Red icon
                    onPressed: () {
                      if (quantity > 1) {
                        setState(() => quantity--);
                      }
                    },
                  ),
                  Text('$quantity', style: Theme.of(context).textTheme.headlineMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green), // Green icon
                    onPressed: () {
                      setState(() => quantity++);
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A), // Purple button
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ตกลง'),
                  onPressed: () => Navigator.of(context).pop(quantity),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _handleBuyNow() async {
    if (widget.post.productId == null || widget.post.productId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โพสต์นี้ไม่ได้ผูกกับสินค้า')),
      );
      return;
    }
    if (widget.post.storeId.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบข้อมูลร้านค้าของโพสต์นี้')),
      );
      return;
    }

    final int? selectedQuantity = await _showQuantityDialog(context);
    if (selectedQuantity == null || selectedQuantity == 0) {
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.post.storeId)
          .collection('products')
          .doc(widget.post.productId)
          .get();

      if (!productDoc.exists) {
        throw Exception('ไม่พบสินค้าชิ้นนี้ในระบบ');
      }
      
      final productData = productDoc.data() as Map<String, dynamic>;

      final singleCartItem = CartItem(
        productId: productDoc.id,
        name: productData['name'] ?? 'ไม่มีชื่อ',
        price: (productData['price'] as num).toDouble(),
        quantity: selectedQuantity,
        imageUrl: productData['imageUrl'] ?? '',
        storeId: widget.post.storeId,
        addedAt: Timestamp.now(), 
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            cartItems: [singleCartItem],
          ),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyPost = widget.currentUserId != null && widget.currentUserId == widget.post.ownerUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // Stronger shadow
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18), // Increased padding
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20, // Larger avatar
                  backgroundColor: Colors.blue.shade100, // Light blue default
                  backgroundImage: widget.post.avatarImageUrl != null && widget.post.avatarImageUrl!.startsWith('http')
                      ? NetworkImage(widget.post.avatarImageUrl!)
                      : null, // No background image if using default icon
                  child: widget.post.avatarImageUrl == null || !widget.post.avatarImageUrl!.startsWith('http')
                      ? Icon(Icons.person, size: 30, color: Colors.blue.shade700) // Default avatar icon
                      : null,
                ),
                const SizedBox(width: 15), // Increased spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.shopName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87), // Bolder, larger
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgoString,
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // Increased padding
                        decoration: BoxDecoration(
                          color: const Color(0xFF0288D1), // Deeper purple for badge
                          borderRadius: BorderRadius.circular(15), // More rounded
                        ),
                        child: Text(
                          '${widget.post.category} | ${widget.post.province}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24), // Brighter red, larger icon
                    onPressed: () => widget.onDelete(widget.post),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              widget.post.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87), // Larger, bolder text
            ),
          ),
          const SizedBox(height: 18),
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              height: 200, // Taller image container
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // More rounded image corners
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
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15)),
              child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)), // Larger icon
            ),
          const SizedBox(height: 18), // Increased spacing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
            child: Row(
              children: [
                if (!widget.isSeller)
                  Expanded( // Use Expanded for both buttons
                    child: ActionButton(
                      text: 'สั่งเลย',
                      onTap: _handleBuyNow,
                      isLoading: _isProcessingOrder,
                      buttonColor: const Color(0xFF6A1B9A), // Deep purple for "Buy Now"
                    ),
                  ),
                
                if (!widget.isSeller) const SizedBox(width: 15), // Increased spacing

                Expanded( // Use Expanded for both buttons
                  child: ActionButton(
                    text: 'ดูหน้าร้าน',
                    onTap: () {
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
                    },
                    buttonColor: Colors.deepOrange.shade400, // Vibrant orange for "View Store"
                  ),
                ),
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
  final bool isLoading;
  final Color buttonColor; // Added custom color parameter

  const ActionButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.buttonColor = const Color(0xFF9C6ADE), // Default color
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, // Use custom color
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // More rounded corners
        ),
        padding: const EdgeInsets.symmetric(vertical: 5), // Increased padding
        elevation: 5, // Added elevation
        shadowColor: buttonColor.withOpacity(0.4), // Shadow matching button color
      ),
      child: isLoading
          ? const SizedBox(
              height: 22, // Slightly larger loading indicator
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.8, // Thicker stroke
              ),
            )
          : Text(
              text,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), // Larger, bolder text
            ),
    );
  }
}
