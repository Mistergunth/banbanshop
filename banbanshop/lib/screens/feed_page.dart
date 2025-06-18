// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  final String selectedProvince;
  final String selectedCategory;

  const FeedPage({
    super.key,
    required this.selectedProvince,
    required this.selectedCategory,
  });

  @override
  // เนื่องจาก createState เป็นส่วนหนึ่งของ StatefulWidget ที่ไม่ได้ถูกเรียกใช้ภายนอกโดยตรง
  // และไม่ได้เป็น public type ที่ต้องการการอ้างอิงถึง libary_private_types_in_public_api
  // จึงไม่จำเป็นต้องใช้ ignore: library_private_types_in_public_api ที่นี่แล้ว
  _FeedPageState createState() => _FeedPageState();
}

class Post {
  final String id;
  final String shopName;
  final String timeAgo;
  final String category;
  final String title;
  final String imageUrl;
  final String avatarImageUrl; // เพิ่ม field นี้
  final String province;
  final String productCategory;

  Post({
    required this.id,
    required this.shopName,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.avatarImageUrl, // กำหนดให้เป็น required
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
  String selectedFilter = 'ฟีดโพสต์';

  // ตัวอย่างข้อมูล Post
  // อัปเดต avatarImageUrl ให้เป็น URL ที่สามารถโหลดได้จริง หรือเป็น asset path ที่ถูกต้อง
  final List<Post> posts = [
    Post(
      id: '1',
      shopName: 'เดอะเต่าถ่านพรีเมี่ยม',
      timeAgo: '1 นาที',
      category: 'อาหาร & เครื่องดื่ม',
      title: 'มาเด้อ เนื้อโคขุน สนใจกด "สั่งเลย"',
      avatarImageUrl: 'assets/images/avatar1.jpg', // ตัวอย่าง URL รูปโปรไฟล์
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
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png', // ตัวอย่าง URL รูปโปรไฟล์
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
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png', // ตัวอย่าง URL รูปโปรไฟล์
      imageUrl: 'https://images.unsplash.com/photo-1542291026-79eddc8727ae?w=400',
      province: 'กรุงเทพมหานคร',
      productCategory: 'กีฬา & กิจกรรม',
    ),
  ];

  List<Post> get filteredPosts {
    // กรองตามจังหวัดและหมวดหมู่ที่ถูกส่งเข้ามา
    final filteredByProvinceAndCategory = posts.where((post) {
      final matchesProvince = widget.selectedProvince == 'ทั้งหมด' || post.province == widget.selectedProvince;
      final matchesCategory = widget.selectedCategory == 'ทั้งหมด' || post.productCategory == widget.selectedCategory;
      return matchesProvince && matchesCategory;
    }).toList();

    // กรองเพิ่มเติมตามข้อความค้นหา (ถ้ามี)
    if (searchController.text.isEmpty) {
      return filteredByProvinceAndCategory;
    } else {
      final query = searchController.text.toLowerCase();
      return filteredByProvinceAndCategory.where((post) {
        return post.title.toLowerCase().contains(query) ||
              post.shopName.toLowerCase().contains(query) ||
              post.category.toLowerCase().contains(query);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      endDrawer: const Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF9C6ADE), 
              ),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w200),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('หน้าแรก'),
              // onTap: () { Navigator.pop(context); /* ไปหน้าแรก */ },
            ),
            ListTile(
              leading: Icon(Icons.storefront_outlined),
              title: Text('ร้านค้าของฉัน'),
              // onTap: () { Navigator.pop(context); /* ไปหน้าร้านค้า */ },
            ),
            ListTile(
              leading: Icon(Icons.favorite_outline),
              title: Text('รายการโปรด'),
              // onTap: () { Navigator.pop(context); /* ไปหน้ารายการโปรด */ },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('ตั้งค่า'),
              // onTap: () { Navigator.pop(context); /* ไปหน้าตั้งค่า */ },
            ),
            Divider(), // เส้นแบ่ง
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('ออกจากระบบ'),
              // onTap: () { Navigator.pop(context); /* Logic ออกจากระบบ */ },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'ค้นหา',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Builder(
                    builder: (BuildContext innerContext) {
                      return IconButton(
                        icon: const Icon(Icons.menu, size: 24),
                        onPressed: () {
                          Scaffold.of(innerContext).openEndDrawer(); 
                        },
                      );
                    },
                  )
                ],
              ),
            ),
            // Filter Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  FilterButton(
                    text: 'ฟีดโพสต์',
                    isSelected: selectedFilter == 'ฟีดโพสต์',
                    onTap: () {
                      setState(() {
                        selectedFilter = 'ฟีดโพสต์';
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  FilterButton(
                    text: 'ร้านค้า',
                    isSelected: selectedFilter == 'ร้านค้า',
                    onTap: () {
                      setState(() {
                        selectedFilter = 'ร้านค้า';
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: filteredPosts.isEmpty
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
                              '${widget.selectedCategory} ใน ${widget.selectedProvince}',
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
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF9C6ADE)),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF9C6ADE)),
            label: 'ตะกร้า',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'โปรไฟล์',
          ),
        ],
        selectedIndex: 0, // ตั้งค่าเริ่มต้นให้ตะกร้าถูกเลือก
        onDestinationSelected: (int value) {
          // สามารถเพิ่ม logic การนำทางไปยังหน้าต่างๆ ได้ที่นี่
          // ตัวอย่างเช่น:
          // if (value == 0) { Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage())); }
          // else if (value == 1) { /* อยู่หน้านี้แล้ว */ }
          // else if (value == 2) { Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())); }
          print('Selected index: $value');
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
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
                  // ใช้ post.avatarImageUrl สำหรับรูปโปรไฟล์
                  backgroundImage: AssetImage(post.avatarImageUrl),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C6ADE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              post.category,
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
                ActionButton(text: 'สั่งเลย'),
                const SizedBox(width: 10),
                ActionButton(text: 'ดูหน้าร้าน'),
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

  const ActionButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}