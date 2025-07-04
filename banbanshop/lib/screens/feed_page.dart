// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, curly_braces_in_flow_control_controls

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
import 'package:banbanshop/screens/post_model.dart'; // Import Post model จากไฟล์แยก
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'dart:async'; // สำหรับ StreamSubscription และ Timer

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

  List<Post> _allPosts = []; // เปลี่ยนเป็น _allPosts เพื่อเก็บโพสต์ทั้งหมดที่ดึงมาจาก Supabase
  bool _isLoadingPosts = true; // สถานะการโหลดโพสต์
  StreamSubscription? _postsSubscription; // สำหรับจัดการ Stream ของ Supabase

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

    _fetchPostsFromSupabase(); // เริ่มดึงข้อมูลโพสต์จาก Supabase
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _postsSubscription?.cancel(); // ยกเลิกการ subscribe เมื่อ widget ถูก dispose
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuilds the UI to re-filter posts based on search query
    });
  }

  // ดึงข้อมูลโพสต์จาก Supabase แบบเรียลไทม์
  void _fetchPostsFromSupabase() {
    setState(() {
      _isLoadingPosts = true;
    });

    _postsSubscription = Supabase.instance.client
        .from('posts')
        .stream(primaryKey: ['id']) // ใช้ stream() สำหรับการอัปเดตแบบเรียลไทม์
        .order('createdAt', ascending: false) // เรียงลำดับตามเวลาสร้างล่าสุด
        .listen((data) {
      if (!mounted) return; // ตรวจสอบว่า widget ยัง mounted อยู่

      // แปลงข้อมูลที่ได้จาก Supabase เป็น List ของ Post objects
      final fetchedPosts = data.map((map) => Post.fromJson(map)).toList();

      setState(() {
        _allPosts = fetchedPosts; // อัปเดตรายการโพสต์
        _isLoadingPosts = false; // หยุดแสดง loading
      });
    }, onError: (error) {
      if (!mounted) return;
      print("Error fetching posts from Supabase: $error");
      setState(() {
        _isLoadingPosts = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงโพสต์: $error')),
      );
    });
  }

  // ฟังก์ชันสำหรับลบโพสต์
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

    if (confirmDelete == true) {
      setState(() {
        _isLoadingPosts = true; // แสดง loading indicator
      });

      try {
        // 1. ลบโพสต์ออกจาก Supabase Database
        await Supabase.instance.client
            .from('posts')
            .delete()
            .eq('id', post.id); // ลบโพสต์ที่มี id ตรงกัน

        // 2. ลบรูปภาพออกจาก Supabase Storage
        // แยก bucket name และ file path จาก URL ของรูปภาพ
        final Uri uri = Uri.parse(post.imageUrl);
        // Path ใน Supabase Storage คือส่วนที่อยู่หลัง '/public/'
        // ตัวอย่าง: /storage/v1/object/public/post_images/user_id/filename.jpg
        // เราต้องการ 'post_images/user_id/filename.jpg'
        final String storagePath = uri.path.substring(uri.path.indexOf('/public/') + '/public/'.length);
        final String bucketName = storagePath.split('/').first; // ควรจะเป็น 'post_images'
        final String filePathInBucket = storagePath.substring(bucketName.length + 1); // Path หลัง bucket name

        await Supabase.instance.client.storage
            .from(bucketName)
            .remove([filePathInBucket]); // ลบไฟล์จาก Storage

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ลบโพสต์และรูปภาพสำเร็จ!')),
          );
        }
      } on StorageException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรูปภาพ (Storage): ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการลบโพสต์: $e')),
          );
        }
      } finally {
        setState(() {
          _isLoadingPosts = false; // ซ่อน loading indicator
        });
      }
    }
  }


  void _onItemTapped(int index) async {
    // ถ้าเลือกแท็บ "สร้างโพสต์" (Index 2)
    if (index == 2) {
      // ตรวจสอบว่าผู้ใช้เป็นผู้ขายหรือไม่
      if (widget.sellerProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องเข้าสู่ระบบในฐานะผู้ขายเพื่อสร้างโพสต์')),
        );
        // กลับไปหน้าเดิม (หน้าแรก)
        setState(() {
          _selectedIndex = 0; 
        });
        return;
      }

      final newPost = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      );

      // ตรวจสอบว่า Widget ยังคง mounted ก่อนที่จะ setState หรือใช้ BuildContext
      if (!mounted) return; 

      if (newPost != null && newPost is Post) {
        // ไม่จำเป็นต้องเพิ่มโพสต์ลงใน _allPosts list ด้วยตนเอง
        // เพราะ Supabase listener (_fetchPostsFromSupabase) จะจัดการให้เอง
        // เมื่อโพสต์ใหม่ถูกบันทึกลง Supabase
        setState(() {
          _selectedIndex = 0; // กลับไปที่หน้าแรก (ฟีดโพสต์)
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์ใหม่ถูกเพิ่มแล้ว!')),
        );
      } else {
        // ถ้าผู้ใช้ยกเลิกการสร้างโพสต์ ให้กลับไปที่หน้าปัจจุบัน (หน้าแรก)
        setState(() {
          _selectedIndex = 0; 
        });
      }
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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

  // ใช้ _allPosts ที่ดึงมาจาก Supabase ในการกรอง
  List<Post> get filteredPosts {
    final filteredByProvinceAndCategory = _allPosts.where((post) {
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
      const CreatePostScreen(), // Index 2: หน้าสร้างโพสต์ (จะถูก push แทนการแสดงใน IndexedStack)
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
                if (mounted) Navigator.pop(context); // ปิด Drawer
              },
            ),
            if (widget.sellerProfile != null) 
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('จัดการร้านค้าของฉัน'),
                onTap: () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้าจัดการร้านค้า')));
                  }
                  if (mounted) Navigator.pop(context); 
                },
              )
            else 
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('รายการโปรด'),
                onTap: () { 
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ไปยังหน้ารายการโปรด')));
                  }
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
              onTap: () async { // Make onTap async
                if (mounted) Navigator.pop(context); 
                try {
                  await Supabase.instance.client.auth.signOut(); // Sign out from Supabase
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      // ignore: use_build_context_synchronously
                      context,
                      MaterialPageRoute(builder: (context) => const SellerLoginScreen()), 
                      (route) => false,
                    );
                  }
                } catch (e) {
                  print('Error signing out: $e');
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e')),
                    );
                  }
                }
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
              child: _isLoadingPosts // แสดง CircularProgressIndicator ขณะโหลด
                  ? const Center(child: CircularProgressIndicator())
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
                          // ส่งฟังก์ชัน _deletePost และ currentUser.id ไปยัง PostCard
                          return PostCard(
                            post: post,
                            onDelete: _deletePost,
                            currentUserId: Supabase.instance.client.auth.currentUser?.id,
                          );
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
        return 'สร้างโพสต์'; // ชื่อหน้าจะถูกกำหนดใน CreatePostScreen เอง
      case 3: // โปรไฟล์
        return widget.sellerProfile != null ? 'บัญชีผู้ขาย' : 'โปรไฟล์ผู้ซื้อ';
      default:
        return 'บ้านบ้านช้อป';
    }
  }
}

// เปลี่ยน PostCard เป็น StatefulWidget เพื่อให้สามารถอัปเดตเวลาได้
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
    _updateTimeAgo(); // คำนวณเวลาครั้งแรก
    // ตั้งค่า Timer เพื่ออัปเดตทุกๆ 1 นาที
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTimeAgo();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิก Timer เมื่อ Widget ถูก dispose
    super.dispose();
  }

  void _updateTimeAgo() {
    if (mounted) { // ตรวจสอบว่า Widget ยัง mounted ก่อน setState
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
    // ตรวจสอบว่าเป็นโพสต์ของผู้ใช้ปัจจุบันหรือไม่
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
                  backgroundImage: widget.post.avatarImageUrl.startsWith('http')
                      ? NetworkImage(widget.post.avatarImageUrl)
                      : AssetImage(widget.post.avatarImageUrl) as ImageProvider,
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
                          Text(
                            _timeAgoString, // <--- ใช้ _timeAgoString ที่คำนวณแล้ว
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
                              '${widget.post.category} | ${widget.post.province}', // แสดงทั้งหมวดหมู่และจังหวัด
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
                // ปุ่มลบ (แสดงเฉพาะโพสต์ของฉัน)
                if (isMyPost)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => widget.onDelete(widget.post), // เรียกใช้ callback onDelete
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
          Container(
            width: double.infinity,
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(widget.post.imageUrl),
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
                  // Handle "Order Now" action
                }),
                const SizedBox(width: 10),
                ActionButton(text: 'ดูหน้าร้าน', onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoreScreenContent(
                        selectedProvince: widget.post.province,
                        selectedCategory: widget.post.productCategory,
                      ),
                    ),
                  );
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
