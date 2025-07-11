// lib/screens/feed_page.dart
// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, curly_braces_in_flow_control_structures, unused_field, unnecessary_non_null_assertion, unused_import

import 'package:banbanshop/screens/seller/seller_order_screen.dart';
import 'package:banbanshop/screens/seller/store_create.dart';
import 'package:flutter/material.dart';
import 'package:banbanshop/widgets/bottom_navbar_widget.dart';
import 'package:banbanshop/screens/models/seller_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/seller_account_screen.dart';
import 'package:banbanshop/screens/buyer/buyer_profile_screen.dart';
import 'package:banbanshop/screens/store_screen_content.dart';
import 'package:banbanshop/screens/create_post.dart';
import 'package:banbanshop/screens/models/post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';
import 'package:banbanshop/screens/role_select.dart';
import 'package:banbanshop/screens/seller/seller_orders_screen.dart';
import 'package:banbanshop/screens/buyer/buyer_cart_screen.dart';

class FeedPage extends StatefulWidget {
  final String selectedProvince;
  final String selectedCategory;
  final SellerProfile? sellerProfile;
  final Store? storeProfile;
  final VoidCallback? onRefresh;

  const FeedPage({
    super.key,
    required this.selectedProvince,
    required this.selectedCategory,
    this.sellerProfile,
    this.storeProfile,
    this.onRefresh,
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C6ADE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF9C6ADE) : Colors.blue, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontSize: 16,
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

  final List<String> _provinces = [
    'ทั้งหมด', 'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น',
    'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร',
    'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี',
    'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร',
    'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต',
    'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด',
    'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม',
    'สมุทรสาคร', 'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ',
  ];

  final List<String> _categories = [
    'ทั้งหมด', 'OTOP', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'สิ่งของเครื่องใช้',
  ];

  List<Post> _allPosts = [];
  bool _isLoadingPosts = true;
  StreamSubscription? _postsSubscription;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms',
    apiKey: '157343641351425',
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU',
  );

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
  void didUpdateWidget(covariant FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProvince != oldWidget.selectedProvince ||
        widget.selectedCategory != oldWidget.selectedCategory) {
      _fetchPostsFromFirestore();
    }
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
        return Post.fromJson({...doc.data()!, 'id': doc.id});
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
        setState(() => _isLoadingPosts = false);
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
      if (widget.sellerProfile != null && widget.storeProfile != null) {
        _navigateToCreatePost();
      } else if (widget.sellerProfile != null && widget.storeProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องสร้างร้านค้าก่อนจึงจะสร้างโพสต์ได้')),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => StoreCreateScreen(onRefresh: widget.onRefresh)));
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
    return widget.sellerProfile != null
        ? const SellerOrdersScreen()
        : const BuyerCartScreen();
  }

  Widget _buildProfilePage() {
    if (widget.sellerProfile != null) {
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
      Container(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (BuildContext innerContext) {
              return IconButton(
                icon: const Icon(Icons.menu, size: 24),
                onPressed: () {
                  Scaffold.of(innerContext).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF9C6ADE)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.storeProfile?.name ?? widget.sellerProfile?.fullName ?? 'ผู้ใช้บ้านบ้านช้อป',
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
              leading: const Icon(Icons.home_outlined),
              title: const Text('หน้าแรก (ฟีดโพสต์)'),
              onTap: () {
                _onItemTapped(0);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('ร้านค้าทั้งหมด'),
              onTap: () {
                setState(() {
                  _selectedTopFilter = 'ร้านค้า';
                  _selectedIndex = 0;
                });
                if (mounted) Navigator.pop(context);
              },
            ),

            // --- ส่วนที่แก้ไข ---
            // แสดงปุ่ม "จัดการร้านค้า" ต่อเมื่อมีข้อมูลร้านค้าแล้วเท่านั้น
            if (widget.storeProfile != null)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('จัดการร้านค้าของฉัน'),
                onTap: () {
                  // ปิด Drawer ก่อน
                  Navigator.pop(context);
                  // จากนั้นค่อยเปิดหน้าใหม่
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
            // --- จบส่วนที่แก้ไข ---

            if (widget.sellerProfile == null) // แสดงเมนูนี้เฉพาะผู้ซื้อ หรือ Guest
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('รายการโปรด'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ฟังก์ชันรายการโปรดยังไม่พร้อมใช้งาน')),
                  );
                  if (mounted) Navigator.pop(context);
                },
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _drawerSelectedProvince,
                decoration: InputDecoration(
                  labelText: 'เลือกจังหวัด',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
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
              leading: const Icon(Icons.logout),
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
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'ค้นหา',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        ),
                        onChanged: (query) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(width: 10),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
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
        isSeller: widget.sellerProfile != null,
        hasStore: widget.storeProfile != null,
      ),
    );
  }

  Widget _buildFeedContent() {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _selectedTopFilter == 'ฟีดโพสต์'
                ? (filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_bag_outlined, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text(
                              'ไม่มีโพสต์ที่ตรงกับเงื่อนไข',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_drawerSelectedCategory ?? 'ทั้งหมด'} ใน ${_drawerSelectedProvince ?? 'ทั้งหมด'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
                          );
                        },
                      ))
                : StoreScreenContent(
                    selectedProvince: _drawerSelectedProvince ?? 'ทั้งหมด',
                    selectedCategory: _drawerSelectedCategory ?? 'ทั้งหมด',
                  ),
          ),
        ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'บ้านบ้านช้อป';
      case 1:
        return widget.sellerProfile != null ? 'รายการออเดอร์' : 'ตะกร้าสินค้า';
      case 2:
        return 'สร้างโพสต์';
      case 3:
        return widget.sellerProfile != null ? 'บัญชีผู้ขาย' : 'โปรไฟล์ผู้ซื้อ';
      default:
        return 'บ้านบ้านช้อป';
    }
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