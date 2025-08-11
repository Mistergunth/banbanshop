// lib/screens/store_screen_content.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';


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
  void didUpdateWidget(covariant StoreScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProvince != oldWidget.selectedProvince ||
        widget.selectedCategory != oldWidget.selectedCategory) {
      _applyFilters();
    }
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
    
    setState(() {
      _filteredStores = tempFiltered;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อร้าน, หมวดหมู่, จังหวัด...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0098DA)), // Blue search icon
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white, // White background for search bar
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              enabledBorder: OutlineInputBorder( // Solid border when enabled
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder( // Blue border when focused
                borderRadius: BorderRadius.circular(30.0),
                borderSide: const BorderSide(color: Color(0xFF0098DA), width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<StoreWithDistance>>(
            future: _storesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0098DA))); // Blue loading indicator
              }
      
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column( // Display error with icon and refresh button
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                        const SizedBox(height: 15),
                        Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _storesFuture = _fetchStoresAndCalculateDistances(); // Retry fetching
                            });
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          label: const Text('ลองอีกครั้ง', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0288D1), // Blue button from icon
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
      
              return _filteredStores.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_outlined, size: 60, color: Colors.grey),
                          const SizedBox(height: 15),
                          const Text(
                            'ไม่พบร้านค้าที่ตรงกับเงื่อนไข',
                            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon( // Added refresh button
                              onPressed: () {
                                _searchController.clear();
                                _applyFilters(); // Apply filters again
                              },
                              icon: const Icon(Icons.clear_all, color: Colors.white),
                              label: const Text('ล้างการค้นหา/ตัวกรอง', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB300), // Yellow/Orange button from icon
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
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
                    );
            },
          ),
        ),
      ],
    );
  }
}

class StoreCard extends StatelessWidget {
  final StoreWithDistance storeData;

  const StoreCard({super.key, required this.storeData});

  Widget _buildStatusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.shade600 : Colors.red.shade600, // Deeper green/red
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20), // More rounded
          bottomLeft: Radius.circular(20), // More rounded
        ),
        boxShadow: [ // Subtle shadow
          BoxShadow(
            color: (isOpen ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        isOpen ? 'เปิด' : 'ปิด',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13, // Slightly larger font
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]), // Larger icon
        const SizedBox(width: 8), // Increased spacing
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[700], fontSize: 14), // Slightly larger font
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = storeData.store;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoreProfileScreen(
              storeId: store.id,
              isSellerView: false,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20), // More rounded for the whole card
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20), // Increased margin
            padding: const EdgeInsets.all(18), // Increased padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // More rounded
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15), // Stronger shadow
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90, // Larger image
                  height: 90, // Larger image
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15), // More rounded
                    image: DecorationImage(
                      image: NetworkImage(store.imageUrl ?? 'https://placehold.co/100x100/EFEFEF/AAAAAA?text=No+Image'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 18), // Increased spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.black87), // Bolder, larger
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        store.description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14), // Slightly larger font
                        maxLines: 2, // Allow more lines for description
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10), // Increased spacing
                      _buildInfoRow(Icons.category_outlined, store.category ?? 'ไม่มีหมวดหมู่'),
                      const SizedBox(height: 6), // Increased spacing
                      _buildInfoRow(Icons.location_city_outlined, store.province),
                      const SizedBox(height: 10), // Increased spacing
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]), // Larger icon
                          const SizedBox(width: 6), // Increased spacing
                          Text(
                            '${storeData.distanceInKm.toStringAsFixed(1)} km',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(width: 20), // Increased spacing
                          const Icon(Icons.star, size: 18, color: Colors.orange), // Larger icon
                          const SizedBox(width: 6), // Increased spacing
                          Text(
                            store.averageRating.toStringAsFixed(1),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildStatusBadge(store.isOpen),
          ),
        ],
      ),
    );
  }
}
