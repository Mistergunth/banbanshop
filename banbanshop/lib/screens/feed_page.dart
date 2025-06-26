// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:banbanshop/widgets/bottom_navbar_widget.dart';
import 'package:banbanshop/screens/profile.dart'; // สำหรับ SellerProfile
import 'package:banbanshop/screens/seller/seller_account_screen.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:banbanshop/screens/seller/seller_orders_screen.dart'; 
import 'package:banbanshop/screens/buyer/buyer_cart_screen.dart'; // สำหรับหน้าตะกร้าสินค้าของผู้ซื้อ
import 'package:banbanshop/screens/buyer/buyer_profile_screen.dart'; // สำหรับหน้าจัดการร้านค้าของผู้ขาย
import 'package:banbanshop/screens/store_screen_content.dart'; // Import ไฟล์หน้าร้านค้า
import 'package:banbanshop/screens/create_post.dart'; // Import ไฟล์สร้างโพสต์ใหม่


class FeedPage extends StatefulWidget {
  final String selectedProvince;
  final String selectedCategory;
  final SellerProfile? sellerProfile; // เพิ่มเข้ามาเพื่อรับข้อมูลผู้ขาย

  const FeedPage({
    super.key,
    required this.selectedProvince,
    required this.selectedCategory,
    this.sellerProfile, // ทำให้เป็น optional ถ้าไม่ได้ล็อกอินเป็นผู้ขาย
  });

  @override
  _FeedPageState createState() => _FeedPageState();
}

class Post {
  final String id;
  final String shopName;
  final String timeAgo;
  final String category;
  final String title;
  final String imageUrl;
  final String avatarImageUrl; 
  final String province;
  final String productCategory;

  Post({
    required this.id,
    required this.shopName,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, 
    required this.province,
    required this.productCategory,
  });
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

  // สถานะสำหรับ Bottom Navbar
  int _selectedIndex = 0; 

  // สถานะสำหรับ Drawer
  String? _drawerSelectedProvince;
  String? _drawerSelectedCategory;

  // รายชื่อจังหวัด (สำหรับ Drawer)
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

  // รายชื่อหมวดหมู่ (สำหรับ Drawer)
  final List<String> _categories = [
    'ทั้งหมด', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'กีฬา & กิจกรรม', 'สิ่งของเครื่องใช้'
  ];

  final List<Post> posts = [
    Post(
      id: '1',
      shopName: 'เดอะเต่าถ่านพรีเมี่ยม',
      timeAgo: '1 นาที',
      category: 'อาหาร & เครื่องดื่ม',
      title: 'มาเด้อ เนื้อโคขุน สนใจกด "สั่งเลย"',
      avatarImageUrl: 'assets/images/avatar1.jpg', 
      imageUrl: 'https://img.wongnai.com/p/1600x0/2021/06/01/354e5af8ab1e40cf85cf3c10f4331677.jpg',
      province: 'สกลนคร',
      productCategory: 'อาหาร & เครื่องดื่ม',
    ),
    Post(
      id: '2',
      shopName: 'ร้านเสื้อผ้าแฟชั่น',
      timeAgo: '15 นาที',
      category: 'เสื้อผ้า',
      title: 'เสื้อยืดคุณภาพดี ราคาถูก มีหลายสี',
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      province: 'สกลนคร',
      productCategory: 'เสื้อผ้า',
    ),
    Post(
      id: '3',
      shopName: 'ร้านอุปกรณ์กีฬา',
      timeAgo: '30 นาที',
      category: 'กีฬา & กิจกรรม',
      title: 'รองเท้าวิ่งรุ่นใหม่ล่าสุด ลด 20%',
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
      imageUrl: 'https://images.unsplash.com/photo-1542291026-79eddc8727ae?w=400',
      province: 'กรุงเทพมหานคร',
      productCategory: 'กีฬา & กิจกรรม',
    ),
    Post(
      id: '4',
      shopName: 'ร้านขายของใช้ในบ้าน',
      timeAgo: '45 นาที',
      category: 'สิ่งของเครื่องใช้',
      title: 'ของใช้ในบ้านน่ารักๆ ราคาพิเศษ',
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
      imageUrl: 'https://images.unsplash.com/photo-1579735706240-a17d5a5b5b0d?w=400',
      province: 'เชียงใหม่',
      productCategory: 'สิ่งของเครื่องใช้',
    ),
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _drawerSelectedProvince = widget.selectedProvince; // กำหนดค่าเริ่มต้นจาก prop
    _drawerSelectedCategory = widget.selectedCategory; // กำหนดค่าเริ่มต้นจาก prop
    
    // หากมี sellerProfile และ province ไม่ได้ถูกตั้งค่า ให้ใช้จังหวัดของผู้ขายเป็นค่าเริ่มต้น
    if (widget.sellerProfile != null && (widget.selectedProvince == 'ทั้งหมด' || widget.selectedProvince.isEmpty)) {
      _drawerSelectedProvince = widget.sellerProfile!.province;
    }
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuilds the UI to re-filter posts based on search query
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // สร้าง Widget สำหรับหน้าตะกร้าสินค้า (Buyer) หรือ รายการออเดอร์ (Seller)
  Widget _buildMiddlePage() {
    if (widget.sellerProfile != null) {
      // ถ้าเป็นผู้ขาย ให้แสดงหน้ารายการออเดอร์
      return SellerOrdersScreen(
      );
    } else {
      // ถ้าเป็นผู้ซื้อ ให้แสดงหน้าตะกร้าสินค้า
      return BuyerCartScreen( 
      );
    }
  }

  // สร้าง Widget สำหรับหน้าโปรไฟล์ (Buyer) หรือ บัญชีผู้ขาย (Seller)
  Widget _buildProfilePage() {
    if (widget.sellerProfile != null) {
      // ถ้าเป็นผู้ขาย ให้แสดง SellerAccountScreen
      return SellerAccountScreen(sellerProfile: widget.sellerProfile);
    } else {
      // ถ้าเป็นผู้ซื้อ ให้แสดงหน้าโปรไฟล์ผู้ซื้อ (Placeholder)
      return BuyerProfileScreen(
);
    }
  }

  List<Post> get filteredPosts {
    final filteredByProvinceAndCategory = posts.where((post) {
      // ใช้ _drawerSelectedProvince และ _drawerSelectedCategory ในการกรอง
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
            post.province.toLowerCase().contains(query); // เพิ่มการค้นหาจากจังหวัด
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // List ของหน้าย่อยสำหรับ IndexedStack
    final List<Widget> pages = [
      _buildFeedContent(), // Index 0: หน้าฟีด (และร้านค้า)
      _buildMiddlePage(), // Index 1: ตะกร้า (ผู้ซื้อ) / ออเดอร์ (ผู้ขาย)
      const CreatePostScreen(), // Index 2: หน้าสร้างโพสต์
      _buildProfilePage(), // Index 3: โปรไฟล์ (ผู้ซื้อ) / บัญชีผู้ขาย (ผู้ขาย)
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        // ปุ่ม Back (leading)
        leading: Navigator.of(context).canPop() 
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null, 
        // Title ของ AppBar
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true, // จัด Title ให้อยู่ตรงกลาง
        // ปุ่ม Menu (actions)
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
              decoration: const BoxDecoration(
                color: Color(0xFF9C6ADE),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.sellerProfile?.fullName ?? 'ผู้ใช้บ้านบ้านช้อป', 
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
                _onItemTapped(0); // สลับไปหน้า Feed
                Navigator.pop(context); // ปิด Drawer
              },
            ),
            if (widget.sellerProfile != null) 
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('จัดการร้านค้าของฉัน'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้าจัดการร้านค้า')));
                  Navigator.pop(context); 
                },
              )
            else 
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('รายการโปรด'),
                onTap: () { 
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้ารายการโปรด')));
                  Navigator.pop(context); 
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
                  });
                },
              ),
            ),
            const Divider(), 
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ออกจากระบบ'),
              onTap: () { 
                Navigator.pop(context); 
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SellerLoginScreen()), 
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column( // เพิ่ม Column ที่นี่เพื่อวาง Search Bar และ Filter Buttons
          children: [
            if (_selectedIndex == 0) // แสดง Search Bar และ Filter Buttons เฉพาะหน้า Feed
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
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
                          setState(() { /* Trigger rebuild for filteredPosts/filteredStores */ });
                        },
                      ),
                    ),
                    const SizedBox(height: 10), // เพิ่มระยะห่างระหว่าง Search bar และปุ่ม Filter
                    // Filter Buttons (ฟีดโพสต์/ร้านค้า)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center, // จัดปุ่ม Filter ให้อยู่ตรงกลาง
                      children: [
                        FilterButton(
                          text: 'ฟีดโพสต์',
                          isSelected: _selectedTopFilter == 'ฟีดโพสต์', 
                          onTap: () {
                            setState(() {
                              _selectedTopFilter = 'ฟีดโพสต์'; 
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
              child: IndexedStack(
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
      ),
    );
  }

  // สร้าง Widget สำหรับส่วนของ Feed Content แยกออกมา
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
                              '$_drawerSelectedCategory ใน $_drawerSelectedProvince',
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
                          return PostCard(post: post);
                        },
                      ))
                : StoreScreenContent( // แสดง StoreScreenContent เมื่อเลือก "ร้านค้า"
                    selectedProvince: _drawerSelectedProvince ?? 'ทั้งหมด',
                    selectedCategory: _drawerSelectedCategory ?? 'ทั้งหมด',
                  ),
          ),
        ),
      ],
    );
  }

  // กำหนดชื่อ AppBar สำหรับหน้าที่ไม่ใช่ Feed
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0: // หน้าแรก (ฟีดโพสต์/ร้านค้า)
        return 'บ้านบ้านช้อป';
      case 1: // ออเดอร์ / ตะกร้า
        return widget.sellerProfile != null ? 'รายการออเดอร์' : 'ตะกร้าสินค้า';
      case 2: // สร้างโพสต์
        return 'สร้างโพสต์';
      case 3: // โปรไฟล์
        return widget.sellerProfile != null ? 'บัญชีผู้ขาย' : 'โปรไฟล์ผู้ซื้อ';
      default:
        return 'บ้านบ้านช้อป';
    }
  }
}


class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
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
                  backgroundImage: post.avatarImageUrl.startsWith('http')
                      ? NetworkImage(post.avatarImageUrl)
                      : AssetImage(post.avatarImageUrl) as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            post.timeAgo,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // กล่องม่วงแสดง หมวดหมู่ และ จังหวัด
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C6ADE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${post.category} | ${post.province}', // แสดงทั้งหมวดหมู่และจังหวัด
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              post.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Image
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(post.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                ActionButton(text: 'สั่งเลย', onTap: () {
                  print('สั่งเลย button pressed for ${post.shopName}');
                }),
                const SizedBox(width: 10),
                ActionButton(text: 'ดูหน้าร้าน', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreScreenContent(
                        selectedProvince: post.province,
                        selectedCategory: post.productCategory,
                      ),
                    ),
                  );
                  print('ดูหน้าร้าน button pressed for ${post.shopName}');
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

  const ActionButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E4FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9C6ADE),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

