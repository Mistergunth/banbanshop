// lib/screens/feed_page.dart

// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, avoid_print, curly_braces_in_flow_control_structures, unused_field, unnecessary_non_null_assertion, unused_import

import 'package:flutter/material.dart';
import 'package:banbanshop/widgets/bottom_navbar_widget.dart';
import 'package:banbanshop/screens/models/seller_profile.dart'; // สำหรับ SellerProfile
import 'package:banbanshop/screens/seller/seller_account_screen.dart';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:banbanshop/screens/seller/seller_orders_screen.dart';
import 'package:banbanshop/screens/buyer/buyer_cart_screen.dart'; // สำหรับหน้าตะกร้าสินค้าของผู้ซื้อ
import 'package:banbanshop/screens/buyer/buyer_profile_screen.dart'; // สำหรับหน้าจัดการร้านค้าของผู้ซื้อ
import 'package:banbanshop/screens/store_screen_content.dart'; // Import ไฟล์หน้าร้านค้า (สำหรับแสดงรายการร้าน)
import 'package:banbanshop/screens/create_post.dart'; // Import ไฟล์สร้างโพสต์ใหม่
import 'package:banbanshop/screens/post_model.dart'; // Import Post model จากไฟล์แยก
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Cloud Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'dart:async'; // สำหรับ StreamSubscription และ Timer
import 'package:cloudinary_sdk/cloudinary_sdk.dart'; // Import Cloudinary SDK
import 'package:banbanshop/screens/seller/store_profile.dart'; // เพิ่ม import สำหรับหน้าร้านค้าเฉพาะร้าน
import 'package:banbanshop/screens/role_select.dart'; // แก้ไข: เปลี่ยน path ให้ถูกต้อง
import 'package:banbanshop/screens/seller/store_create.dart'; // เพิ่ม import สำหรับ StoreCreateScreen


class FeedPage extends StatefulWidget {
  // ทำให้ selectedProvince และ selectedCategory เป็น nullable
  final String? selectedProvince;
  final String? selectedCategory; // ใช้สำหรับ filter feed
  final SellerProfile? sellerProfile; // รับ SellerProfile เข้ามา (แต่จะใช้สถานะภายในเป็นหลัก)

  const FeedPage({
    super.key,
    this.selectedProvince,
    this.selectedCategory,
    this.sellerProfile,
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
  late String _drawerSelectedProvince;
  late String _drawerSelectedCategory;

  // รายชื่อจังหวัด (สำหรับ Drawer) - ใช้งานใน DropdownButtonFormField
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

  // รายชื่อหมวดหมู่ (สำหรับ Drawer) - ใช้งานใน DropdownButtonFormField
  final List<String> _categories = [
    'ทั้งหมด', 'OTOP', 'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'สิ่งของเครื่องใช้',
  ];

  List<Post> _allPosts = []; // เปลี่ยนเป็น _allPosts เพื่อเก็บโพสต์ทั้งหมดที่ดึงมาจาก Firestore
  bool _isLoadingPosts = true; // สถานะการโหลดโพสต์
  StreamSubscription? _postsSubscription; // สำหรับจัดการ Stream ของ Firestore

  // เพิ่มตัวแปรสำหรับสถานะร้านค้าของผู้ขาย - ใช้งานใน _navigateToCreatePost และ _loadSellerAndStoreStatus
  bool _isSeller = false; // สถานะว่าเป็นผู้ขายหรือไม่
  bool _sellerHasStore = false; // สถานะว่าผู้ขายมีร้านค้าแล้วหรือไม่
  String? _sellerStoreId;
  String? _sellerShopName; // เก็บชื่อร้านของผู้ขายที่ล็อกอินอยู่
  String? _sellerFullName; // เก็บชื่อเต็มของผู้ขายที่ล็อกอินอยู่
  String? _sellerEmail; // เก็บ email ของผู้ขายที่ล็อกอินอยู่
  String? _sellerProvince; // เก็บจังหวัดของผู้ขายที่ล็อกอินอยู่
  String? _sellerPhoneNumber; // เพิ่ม: เก็บเบอร์โทรศัพท์ของผู้ขาย
  String? _sellerIdCardNumber; // เพิ่ม: เก็บเลขบัตรประชาชนของผู้ขาย
  String? _sellerPassword; // เพิ่ม: เก็บ password ของผู้ขาย (ควรระมัดระวังในการจัดการข้อมูลนี้)


  // กำหนดค่า Cloudinary ของคุณที่นี่ (สำหรับลบรูปภาพ)
  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', // <-- แทนที่ด้วย Cloud Name ของคุณ
    apiKey: '157343641351425', // <-- ต้องมีสำหรับ Signed Deletion
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', // <-- ต้องมีสำหรับ Signed Deletion
  );

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    // กำหนดค่าเริ่มต้นให้กับ _drawerSelectedProvince และ _drawerSelectedCategory
    _drawerSelectedProvince = widget.selectedProvince ?? 'ทั้งหมด';
    _drawerSelectedCategory = widget.selectedCategory ?? 'ทั้งหมด';

    _loadSellerAndStoreStatus(); // โหลดสถานะผู้ใช้และร้านค้าเมื่อ init
    _fetchPostsFromFirestore(); // เริ่มดึงข้อมูลโพสต์จาก Firestore
  }

  @override
  void didUpdateWidget(covariant FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // หากมีการเปลี่ยนแปลงใน widget.sellerProfile หรือ filter ให้รีโหลดสถานะและโพสต์
    if (widget.sellerProfile != oldWidget.sellerProfile ||
        widget.selectedProvince != oldWidget.selectedProvince ||
        widget.selectedCategory != oldWidget.selectedCategory) {
      _loadSellerAndStoreStatus();
      _drawerSelectedProvince = widget.selectedProvince ?? 'ทั้งหมด';
      _drawerSelectedCategory = widget.selectedCategory ?? 'ทั้งหมด';
      _fetchPostsFromFirestore();
    }
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
      // Trigger rebuild for filteredPosts/filteredStores
    });
  }

  // แก้ไข: เปลี่ยนชื่อเป็น _loadSellerAndStoreStatus เพื่อให้ครอบคลุมทั้งผู้ใช้และร้านค้า
  Future<void> _loadSellerAndStoreStatus() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(currentUser.uid)
            .get();

        if (sellerDoc.exists) {
          final data = sellerDoc.data() as Map<String, dynamic>;
          setState(() {
            _isSeller = true; // ผู้ใช้เป็นผู้ขาย
            _sellerHasStore = data['hasStore'] ?? false;
            _sellerStoreId = data['storeId'];
            _sellerShopName = data['shopName'];
            _sellerFullName = data['fullName'] ?? ''; // ดึงชื่อเต็ม
            _sellerEmail = data['email'] ?? ''; // ดึงอีเมล
            _sellerProvince = data['province'] ?? ''; // ดึงจังหวัด
            _sellerPhoneNumber = data['phoneNumber'] ?? ''; // ดึงเบอร์โทร
            _sellerIdCardNumber = data['idCardNumber'] ?? ''; // ดึงเลขบัตรประชาชน
            _sellerPassword = data['password'] ?? ''; // ดึง password

            // หากจังหวัดที่เลือกใน Drawer เป็น 'ทั้งหมด' หรือว่าง ให้ใช้จังหวัดของผู้ขายเป็นค่าเริ่มต้น
            if (_drawerSelectedProvince == 'ทั้งหมด' || _drawerSelectedProvince.isEmpty) {
              _drawerSelectedProvince = _sellerProvince ?? 'ทั้งหมด';
            }
          });
        } else {
          // ถ้าไม่มีข้อมูลใน collection 'sellers' แสดงว่าเป็นผู้ซื้อ
          setState(() {
            _isSeller = false;
            _sellerHasStore = false;
            _sellerStoreId = null;
            _sellerShopName = null;
            _sellerFullName = null;
            _sellerEmail = currentUser.email; // ใช้ email ของ Firebase Auth
            _sellerProvince = null;
            _sellerPhoneNumber = null;
            _sellerIdCardNumber = null;
            _sellerPassword = null;
          });
        }
      } catch (e) {
        print('Error loading seller/store status: $e');
        setState(() {
          _isSeller = false; // เกิดข้อผิดพลาด ให้ถือว่าเป็นผู้ซื้อ
          _sellerHasStore = false;
          _sellerStoreId = null;
          _sellerShopName = null;
          _sellerFullName = null;
          _sellerEmail = currentUser.email; // ใช้ email ของ Firebase Auth
          _sellerProvince = null;
          _sellerPhoneNumber = null;
          _sellerIdCardNumber = null;
          _sellerPassword = null;
        });
      }
    } else {
      // ผู้ใช้ไม่ได้ล็อกอิน
      setState(() {
        _isSeller = false;
        _sellerHasStore = false;
        _sellerStoreId = null;
        _sellerShopName = null;
        _sellerFullName = null;
        _sellerEmail = null; // ไม่มี email ถ้าไม่ได้ล็อกอิน
        _sellerProvince = null;
        _sellerPhoneNumber = null;
        _sellerIdCardNumber = null;
        _sellerPassword = null;
      });
    }
  }

  // ดึงข้อมูลโพสต์จาก Firestore แบบเรียลไทม์
  void _fetchPostsFromFirestore() {
    _postsSubscription?.cancel(); // ยกเลิก subscription เดิม
    setState(() {
      _isLoadingPosts = true;
      _allPosts = []; // Clear posts ก่อนโหลดใหม่
    });

    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('posts');

    // ใช้ _drawerSelectedProvince และ _drawerSelectedCategory ในการกรอง
    if (_drawerSelectedProvince != 'ทั้งหมด' && _drawerSelectedProvince.isNotEmpty) {
      query = query.where('province', isEqualTo: _drawerSelectedProvince);
    }
    if (_drawerSelectedCategory != 'ทั้งหมด' && _drawerSelectedCategory.isNotEmpty) {
      query = query.where('product_category', isEqualTo: _drawerSelectedCategory);
    }

    // เพิ่ม orderBy หลัง where เพื่อแก้ปัญหา Index
    query = query.orderBy('created_at', descending: true);


    _postsSubscription = query.snapshots().listen((snapshot) {
      if (!mounted) return; // ตรวจสอบว่า widget ยัง mounted อยู่

      // แปลง QuerySnapshot เป็น List ของ Post objects
      final fetchedPosts = snapshot.docs.map((doc) {
        // ใช้ doc.id เป็น id ของ Post
        return Post.fromJson({...doc.data()!, 'id': doc.id});
      }).toList();

      setState(() {
        _allPosts = fetchedPosts; // อัปเดตรายการโพสต์
        _isLoadingPosts = false; // หยุดแสดง loading
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
        // 1. ลบโพสต์ออกจาก Firestore
        await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();

        // 2. ลบรูปภาพออกจาก Cloudinary
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

  void _navigateToCreatePost() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบในฐานะผู้ขายเพื่อสร้างโพสต์')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerLoginScreen()));
      return;
    }

    // ตรวจสอบว่าผู้ขายมีร้านค้าแล้วหรือไม่ โดยใช้ _sellerHasStore
    if (!_sellerHasStore || _sellerStoreId == null || _sellerShopName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาสร้างร้านค้าก่อนทำการโพสต์')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreCreateScreen()))
          .then((_) => _loadSellerAndStoreStatus()); // รีโหลดสถานะเมื่อกลับมา
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          shopName: _sellerShopName!, // ส่ง shopName จากสถานะ
          storeId: _sellerStoreId!, // ส่ง storeId จากสถานะ
        ),
      ),
    ).then((_) {
      // เมื่อกลับมาจาก CreatePostScreen ให้รีโหลดโพสต์เพื่อแสดงโพสต์ใหม่ทันที
      _fetchPostsFromFirestore();
    });
  }

  void _onItemTapped(int index) async {
    // Index 2 คือปุ่ม "สร้างโพสต์"
    if (index == 2) {
      // ตรวจสอบว่าเป็นผู้ขายและมีร้านค้าแล้วหรือไม่ โดยใช้ _isSeller และ _sellerHasStore
      if (_isSeller && _sellerHasStore) {
        _navigateToCreatePost();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องเป็นผู้ขายและมีร้านค้าก่อนจึงจะสร้างโพสต์ได้')),
        );
        setState(() {
          _selectedIndex = 0; // กลับไปที่หน้า Feed
        });
        return;
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // สร้าง Widget สำหรับหน้าตะกร้าสินค้า (Buyer) หรือ รายการออเดอร์ (Seller)
  Widget _buildMiddlePage() {
    if (_isSeller) { // ใช้ _isSeller
      // ถ้าเป็นผู้ขาย ให้แสดงหน้ารายการออเดอร์
      return const SellerOrdersScreen();
    } else {
      // ถ้าเป็นผู้ซื้อ ให้แสดงหน้าตะกร้าสินค้า
      return const BuyerCartScreen();
    }
  }

  // สร้าง Widget สำหรับหน้าโปรไฟล์ (Buyer) หรือ บัญชีผู้ขาย (Seller)
  Widget _buildProfilePage() {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (_isSeller) { // ถ้าผู้ใช้ปัจจุบันเป็นผู้ขาย
      return SellerAccountScreen(
        sellerProfile: SellerProfile( // สร้าง SellerProfile จากสถานะภายใน
          fullName: _sellerFullName ?? '',
          phoneNumber: _sellerPhoneNumber ?? '',
          idCardNumber: _sellerIdCardNumber ?? '',
          province: _sellerProvince ?? '',
          password: _sellerPassword ?? '', // ควรระมัดระวังในการจัดการ password
          email: _sellerEmail ?? '',
          hasStore: _sellerHasStore,
          storeId: _sellerStoreId,
          shopName: _sellerShopName,
          // shopAvatarImageUrl, shopPhoneNumber, shopLatitude, shopLongitude อาจจะต้องดึงเพิ่ม
          // หรือทำให้เป็น optional ใน SellerProfile constructor ถ้าไม่จำเป็นต้องส่งเสมอ
        ),
      );
    } else { // ถ้าผู้ใช้ปัจจุบันไม่ใช่ผู้ขาย (อาจจะเป็นผู้ซื้อที่ล็อกอินแล้ว หรือยังไม่ได้ล็อกอิน)
      // ตรวจสอบว่ามีผู้ใช้ล็อกอินอยู่หรือไม่
      if (currentUser != null) {
        // ถ้ามีผู้ใช้ล็อกอินอยู่ (เป็นผู้ซื้อ) ให้แสดงหน้าโปรไฟล์ผู้ซื้อแบบแก้ไขได้
        return BuyerProfileScreen(
          email: currentUser.email, // ส่งอีเมลของผู้ใช้ที่ล็อกอินอยู่
        );
      } else {
        // ถ้าไม่มีผู้ใช้ล็อกอินอยู่เลย ให้แสดงหน้าโปรไฟล์ผู้ซื้อแบบมีปุ่ม Login/Register
        return const BuyerProfileScreen(); // ไม่ต้องส่ง email เพราะ BuyerProfileScreen จะจัดการเอง
      }
    }
  }

  // ใช้ _allPosts ที่ดึงมาจาก Firestore ในการกรอง
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
      Container(), // Index 2: Placeholder สำหรับปุ่มสร้างโพสต์ (เนื่องจากเป็น Action)
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
                      // แสดงชื่อร้านก่อน ถ้าเป็นผู้ขายและมีชื่อร้าน
                      _isSeller && _sellerShopName != null && _sellerShopName!.isNotEmpty
                          ? _sellerShopName!
                          : _sellerFullName ?? 'ผู้ใช้บ้านบ้านช้อป', // ถ้าไม่มีชื่อร้าน/เป็นผู้ซื้อ ให้แสดงชื่อเต็ม
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_isSeller) // แสดงข้อมูลนี้เฉพาะผู้ขาย
                      Text(
                        '${_sellerProvince ?? ''} | ${_sellerEmail ?? ''}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                      )
                    else if (FirebaseAuth.instance.currentUser != null) // แสดงอีเมลผู้ซื้อที่ล็อกอินอยู่
                      Text(
                        FirebaseAuth.instance.currentUser!.email ?? 'ไม่ระบุอีเมล',
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
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('ร้านค้าทั้งหมด'),
              onTap: () {
                setState(() {
                  _selectedTopFilter = 'ร้านค้า'; // Set filter to stores
                  _selectedIndex = 0; // Go to feed page
                });
                if (mounted) Navigator.pop(context); // Close Drawer
              },
            ),
            if (_isSeller) // แสดงเมนูนี้เฉพาะผู้ขาย
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('จัดการร้านค้าของฉัน'),
                onTap: () {
                  if (_sellerStoreId != null && _sellerStoreId!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreProfileScreen(
                          storeId: _sellerStoreId!,
                          isSellerView: true,
                        ),
                      ),
                    ).then((_) {
                      // เมื่อกลับมาจากการจัดการร้านค้า ให้รีโหลดสถานะผู้ขาย
                      _loadSellerAndStoreStatus();
                      _fetchPostsFromFirestore(); // อาจจะรีโหลดโพสต์ด้วย
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('คุณยังไม่มีร้านค้า กรุณาสร้างร้านค้าก่อน')),
                    );
                  }
                  if (mounted) Navigator.pop(context);
                },
              )
            else ...[
              // แสดงเมนูนี้เฉพาะผู้ซื้อ
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
            ],

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
                    _drawerSelectedProvince = newValue ?? 'ทั้งหมด'; // กำหนดค่าเริ่มต้นถ้าเป็น null
                    _fetchPostsFromFirestore(); // รีโหลดโพสต์เมื่อจังหวัดเปลี่ยน
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
                    _drawerSelectedCategory = newValue ?? 'ทั้งหมด'; // กำหนดค่าเริ่มต้นถ้าเป็น null
                    _fetchPostsFromFirestore(); // รีโหลดโพสต์เมื่อหมวดหมู่เปลี่ยน
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
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const RoleSelectPage()), // กลับไปหน้าเลือกบทบาท
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
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
                          setState(() {
                            /* Trigger rebuild for filteredPosts/filteredStores */
                          });
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
                              _fetchPostsFromFirestore(); // รีโหลดโพสต์เมื่อเปลี่ยน Filter
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
                              // ไม่ต้อง fetchPostsFromFirestore เพราะ StoreScreenContent จะจัดการเอง
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoadingPosts && _selectedTopFilter == 'ฟีดโพสต์' // แสดง CircularProgressIndicator ขณะโหลดโพสต์
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
                  : IndexedStack( // ใช้ IndexedStack เพื่อสลับเนื้อหาของแท็บ
                      index: _selectedIndex,
                      children: pages,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbarWidget( // ใช้ BottomNavbarWidget
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped, // ใช้ onItemSelected
        isSeller: _isSeller, // ส่งค่า isSeller จากสถานะภายใน
        hasStore: _sellerHasStore, // ส่งค่า hasStore จากสถานะภายใน
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
                              '${_drawerSelectedCategory} ใน ${_drawerSelectedProvince}',
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
                          // ส่งฟังก์ชัน _deletePost และ currentUser.uid ไปยัง PostCard
                          return PostCard(
                            post: post,
                            onDelete: _deletePost,
                            currentUserId: FirebaseAuth.instance.currentUser?.uid,
                          );
                        },
                      ))
                : StoreScreenContent( // แสดง StoreScreenContent เมื่อเลือก "ร้านค้า"
                    selectedProvince: _drawerSelectedProvince,
                    selectedCategory: _drawerSelectedCategory,
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
        return _isSeller ? 'รายการออเดอร์' : 'ตะกร้าสินค้า'; // ใช้ _isSeller
      case 2:
        return 'บ้านบ้านช้อป'; // ชื่อหน้าจะถูกกำหนดใน CreatePostScreen เอง
      case 3: // โปรไฟล์
        return _isSeller ? 'บัญชีผู้ขาย' : 'โปรไฟล์ผู้ซื้อ'; // ใช้ _isSeller
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
                  backgroundColor: Colors.grey[200], // เพิ่มสีพื้นหลัง
                  backgroundImage: widget.post.avatarImageUrl != null && widget.post.avatarImageUrl!.startsWith('http')
                      ? NetworkImage(widget.post.avatarImageUrl!)
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider, // Fallback image
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
                              _timeAgoString, // <--- ใช้ _timeAgoString ที่คำนวณแล้ว
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis, // เพิ่ม ellipsis หากข้อความยาวเกิน
                            ),
                          ),
                          const SizedBox(width: 8),
                          // กล่องม่วงแสดง หมวดหมู่ และ จังหวัด
                          Flexible(
                            child: Container(
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
                                overflow: TextOverflow.ellipsis, // เพิ่ม ellipsis หากข้อความยาวเกิน
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
                  // ตรวจสอบว่ามี storeId ก่อนนำทาง
                  if (widget.post.storeId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoreProfileScreen(
                          storeId: widget.post.storeId,
                          isSellerView: false, // มุมมองของผู้ซื้อ
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
          backgroundColor: const Color(0xFF9C6ADE), // สีปุ่ม
          foregroundColor: Colors.white, // สีข้อความ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // ขอบมน
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
