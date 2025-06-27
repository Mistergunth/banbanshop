import 'package:flutter/material.dart';

class StoreScreenContent extends StatefulWidget {
  // รับ province และ category เพื่อใช้ในการกรองร้านค้า
  final String selectedProvince;
  final String selectedCategory;

  const StoreScreenContent({
    super.key,
    required this.selectedProvince,
    required this.selectedCategory,
  });

  @override
  State<StoreScreenContent> createState() => _StoreScreenContentState();
}

class StoreItem {
  final String name;
  final String description;
  final double distance;
  final double rating;
  final String imageUrl;
  final String province; // เพิ่มจังหวัดของร้าน
  final String category; // เพิ่มหมวดหมู่ของร้าน

  StoreItem({
    required this.name,
    required this.description,
    required this.distance,
    required this.rating,
    required this.imageUrl,
    required this.province,
    required this.category,
  });
}

class _StoreScreenContentState extends State<StoreScreenContent> {
  final TextEditingController _searchController = TextEditingController();

  // ตัวอย่างข้อมูลร้านค้า (สามารถเชื่อมกับ Backend ในอนาคต)
  final List<StoreItem> _allStores = [
    StoreItem(
      name: 'ดอนกอยผ้าคราม',
      description: 'ผ้าครามสวย ๆ เส้นใยธรรมชาติ 100% พร้อมส่ง',
      distance: 1.0,
      rating: 4.8,
      imageUrl: 'https://placehold.co/100x100/A0E7E2/000000?text=Store1', // Placeholder image
      province: 'สกลนคร',
      category: 'เสื้อผ้า',
    ),
    StoreItem(
      name: 'เนื้อโคขุนโพนยางคำ',
      description: 'เนื้อวัวคุณภาพดีพร้อมทาน',
      distance: 2.0,
      rating: 4.9,
      imageUrl: 'https://placehold.co/100x100/FFDDC1/000000?text=Store2', // Placeholder image
      province: 'สกลนคร',
      category: 'อาหาร & เครื่องดื่ม',
    ),
    StoreItem(
      name: 'เครื่องจักสานไม้ไผ่',
      description: 'สินค้าทำมือคุณภาพดี การันตี 100%',
      distance: 3.0,
      rating: 4.8,
      imageUrl: 'https://placehold.co/100x100/CCE8CC/000000?text=Store3', // Placeholder image
      province: 'อุดรธานี',
      category: 'สิ่งของเครื่องใช้',
    ),
     StoreItem(
      name: 'ร้านชุดว่ายน้ำสุดแซ่บ',
      description: 'ชุดว่ายน้ำหลากหลายสไตล์',
      distance: 0.5,
      rating: 4.5,
      imageUrl: 'https://placehold.co/100x100/D0F0C0/000000?text=Store4', // Placeholder image
      province: 'กรุงเทพมหานคร',
      category: 'เสื้อผ้า',
    ),
    StoreItem(
      name: 'ร้านอาหารทะเลสดๆ',
      description: 'อาหารทะเลจากทะเลอันดามัน',
      distance: 5.0,
      rating: 4.7,
      imageUrl: 'https://placehold.co/100x100/FFF8DC/000000?text=Store5', // Placeholder image
      province: 'ภูเก็ต',
      category: 'อาหาร & เครื่องดื่ม',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Rebuild UI to filter stores based on search query
    });
  }

  // ฟิลเตอร์ร้านค้าตามจังหวัดและหมวดหมู่ที่ได้รับจาก FeedPage
  List<StoreItem> get _filteredStores {
    final filteredByProps = _allStores.where((store) {
      final matchesProvince = widget.selectedProvince == 'ทั้งหมด' || store.province == widget.selectedProvince;
      final matchesCategory = widget.selectedCategory == 'ทั้งหมด' || store.category == widget.selectedCategory;
      return matchesProvince && matchesCategory;
    }).toList();

    if (_searchController.text.isEmpty) {
      return filteredByProps;
    } else {
      final query = _searchController.text.toLowerCase();
      return filteredByProps.where((store) {
        return store.name.toLowerCase().contains(query) ||
               store.description.toLowerCase().contains(query) ||
               store.province.toLowerCase().contains(query) || // เพิ่มการค้นหาจากจังหวัด
               store.category.toLowerCase().contains(query); // เพิ่มการค้นหาจากหมวดหมู่
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _filteredStores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined, size: 50, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text(
                        'ไม่มีร้านค้าที่ตรงกับเงื่อนไข',
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
                  itemCount: _filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = _filteredStores[index];
                    return StoreCard(store: store);
                  },
                ),
        ),
      ],
    );
  }
}

class StoreCard extends StatelessWidget {
  final StoreItem store;

  const StoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(store.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Store Details
          Expanded( // ใช้ Expanded เพื่อให้ Column นี้ใช้พื้นที่ที่เหลือทั้งหมด
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  store.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    // ใช้ Flexible เพื่อให้ข้อความระยะทางไม่ล้น
                    Flexible( 
                      child: Text(
                        '${store.distance.toStringAsFixed(1)} km', // แสดงระยะทาง
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.star, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    // ใช้ Flexible เพื่อให้ข้อความคะแนนไม่ล้น
                    Flexible( 
                      child: Text(
                        store.rating.toStringAsFixed(1), // แสดงคะแนน
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // ใช้ Expanded เพื่อให้ Container นี้ใช้พื้นที่ที่เหลือทั้งหมด
                    Expanded( 
                      child: Container( // กล่องแสดงหมวดหมู่และจังหวัดของร้าน
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4FF), // สีที่แตกต่างจาก PostCard เพื่อให้แยกแยะได้
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${store.category} | ${store.province}', // แสดงทั้งหมวดหมู่และจังหวัด
                          style: const TextStyle(
                            color: Color(0xFF9C6ADE),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1, // จำกัดให้แสดงแค่ 1 บรรทัด
                          overflow: TextOverflow.ellipsis, // หากล้นให้แสดง ...
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
    );
  }
}
