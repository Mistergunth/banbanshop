import 'package:flutter/material.dart';

class FeedPage extends StatefulWidget {
  final String selectedProvince;
  final String selectedCategory;

  const FeedPage({super.key, 
    required this.selectedProvince,
    required this.selectedCategory,
  });

  // ignore: empty_constructor_bodies
  @override
  // ignore: library_private_types_in_public_api
  _FeedPageState createState() => _FeedPageState();
}

class Post {
  final String id;
  final String shopName;
  final String timeAgo;
  final String category;
  final String title;
  final String imageUrl;
  final String province;
  final String productCategory;

  Post({
    required this.id,
    required this.shopName,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.imageUrl,
    required this.province,
    required this.productCategory,
  });
}

class _FeedPageState extends State<FeedPage> {
  TextEditingController searchController = TextEditingController();
  String selectedFilter = 'ฟีดโพสต์';

  List<Post> posts = [
    Post(
      id: '1',
      shopName: 'เดอะเต่าถ่านพรีเมี่ยม',
      timeAgo : '1 นาที',
      category: 'อาหาร & เครื่องดื่ม',
      title: 'มาเด้อ เนื้อโคขุน สนใจกด "สั่งเลย"',
      imageUrl: 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=400',
      province: 'สกลนคร',
      productCategory: 'อาหาร & เครื่องดื่ม',
    ),
    Post(
      id: '2',
      shopName: 'ร้านเสื้อผ้าแฟชั่น',
      timeAgo: '15 นาที',
      category: 'เสื้อผ้า',
      title: 'เสื้อยืดคุณภาพดี ราคาถูก มีหลายสี',
      imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      province: 'สกลนคร',
      productCategory: 'เสื้อผ้า',
    ),

  ];

  List<Post> get filteredPosts {
    return posts.where((post) {
      final matchesProvince = post.province == widget.selectedProvince;
      final matchesCategory = post.productCategory == widget.selectedCategory;
      return matchesProvince && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8F4FD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 20),
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
                        decoration: InputDecoration(
                          hintText: 'ค้นหา',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500],size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10)
                        ),
                      ),
                    ),
                    ),
                  SizedBox(width: 10),
                  Icon(Icons.menu, size: 24)
                ],
              ),
              
            )
          ],
        ) ,),
    );
  }
}
