// lib/screens/store_screen_content.dart (Upgraded)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/store_profile.dart'; // [EDIT] เพิ่ม Import สำหรับหน้าร้านค้า

// Helper class เพื่อเก็บข้อมูลร้านค้าพร้อมระยะทาง
class StoreWithDistance {
  final Store store;
  final double distanceInKm;

  StoreWithDistance({required this.store, required this.distanceInKm});
}

class StoreScreenContent extends StatefulWidget {
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

class _StoreScreenContentState extends State<StoreScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<StoreWithDistance>> _storesFuture;
  List<StoreWithDistance> _allStores = [];
  List<StoreWithDistance> _filteredStores = [];

  @override
  void initState() {
    super.initState();
    _storesFuture = _fetchStoresAndCalculateDistances();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('กรุณาเปิดบริการตำแหน่ง (GPS)');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('คุณปฏิเสธการเข้าถึงตำแหน่ง');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('การเข้าถึงตำแหน่งถูกปฏิเสธถาวร');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<List<StoreWithDistance>> _fetchStoresAndCalculateDistances() async {
    try {
      final Position userPosition = await _determinePosition();
      final QuerySnapshot storeSnapshot =
          await FirebaseFirestore.instance.collection('stores').get();

      if (storeSnapshot.docs.isEmpty) {
        return [];
      }

      List<StoreWithDistance> storesWithDistance = [];
      for (var doc in storeSnapshot.docs) {
        final store = Store.fromFirestore(doc);
        if (store.latitude != null && store.longitude != null) {
          final double distanceInMeters = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            store.latitude!,
            store.longitude!,
          );
          storesWithDistance.add(StoreWithDistance(
            store: store,
            distanceInKm: distanceInMeters / 1000,
          ));
        }
      }
      
      storesWithDistance.sort((a, b) => a.distanceInKm.compareTo(b.distanceInKm));
      
      _allStores = storesWithDistance;
      _applyFilters();

      return _filteredStores;
    } catch (e) {
      throw Exception('Failed to load stores: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    List<StoreWithDistance> tempFiltered = _allStores;

    if (widget.selectedProvince != 'ทั้งหมด') {
        tempFiltered = tempFiltered.where((item) => item.store.province == widget.selectedProvince).toList();
    }
    if (widget.selectedCategory != 'ทั้งหมด') {
        tempFiltered = tempFiltered.where((item) => item.store.category == widget.selectedCategory).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      tempFiltered = tempFiltered.where((item) {
        final store = item.store;
        return (store.name.toLowerCase().contains(query)) ||
               (store.description.toLowerCase().contains(query)) ||
               (store.province.toLowerCase().contains(query)) ||
               (store.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    _filteredStores = tempFiltered;
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreWithDistance>>(
      future: _storesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'เกิดข้อผิดพลาด: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อร้าน, หมวดหมู่, จังหวัด...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: _filteredStores.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_outlined, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          const Text(
                            'ไม่พบร้านค้าที่ตรงกับเงื่อนไข',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        setState(() {
                          _storesFuture = _fetchStoresAndCalculateDistances();
                        });
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: _filteredStores.length,
                        itemBuilder: (context, index) {
                          final storeData = _filteredStores[index];
                          return StoreCard(storeData: storeData);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class StoreCard extends StatelessWidget {
  final StoreWithDistance storeData;

  const StoreCard({super.key, required this.storeData});

  @override
  Widget build(BuildContext context) {
    final store = storeData.store;
    // [EDIT] ห่อด้วย InkWell เพื่อให้คลิกได้
    return InkWell(
      onTap: () {
        // นำทางไปยังหน้ารายละเอียดร้านค้า
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreProfileScreen(
              storeId: store.id,
              isSellerView: false, // ผู้ซื้อเป็นคนดู
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(15), // ทำให้เอฟเฟกต์การคลิกเป็นวงกลม
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(store.imageUrl ?? 'https://placehold.co/100x100/EFEFEF/AAAAAA?text=No+Image'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    store.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${storeData.distanceInKm.toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 15),
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        store.averageRating.toStringAsFixed(1),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          store.category ?? 'ไม่มีหมวดหมู่',
                          style: const TextStyle(
                            color: Color(0xFF9C6ADE),
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
    );
  }
}
