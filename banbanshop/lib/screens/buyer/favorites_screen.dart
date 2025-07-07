// lib/screens/buyer/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/seller/store_profile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // ใช้ FutureBuilder เพื่อจัดการการดึงข้อมูลแบบอะซิงโครนัส
  Future<List<Store>> _fetchFavoriteStores() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // คืนค่า list ว่าง ถ้าผู้ใช้ยังไม่ได้ล็อคอิน
      return [];
    }

    // 1. ดึง ID ของร้านค้าโปรดทั้งหมด
    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('buyers')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();

    if (favoritesSnapshot.docs.isEmpty) {
      // คืนค่า list ว่าง ถ้ายังไม่มีร้านค้าโปรด
      return [];
    }

    final storeIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();

    // 2. ดึงข้อมูลของร้านค้าแต่ละร้านจาก ID ที่ได้มา
    List<Store> favoriteStores = [];
    for (String storeId in storeIds) {
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
        if (storeDoc.exists) {
          favoriteStores.add(Store.fromFirestore(storeDoc));
        }
      } catch (e) {
        print('Could not fetch store with ID: $storeId. Error: $e');
      }
    }

    return favoriteStores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ร้านค้าโปรด'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Store>>(
        future: _fetchFavoriteStores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ยังไม่มีร้านค้าโปรด',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'ลองกดรูปหัวใจที่หน้าร้านค้าที่คุณชื่นชอบ',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final favoriteStores = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: favoriteStores.length,
            itemBuilder: (context, index) {
              final store = favoriteStores[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                clipBehavior: Clip.antiAlias, // เพื่อให้ขอบมนมีผลกับ ListTile
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: store.imageUrl != null && store.imageUrl!.isNotEmpty
                        ? NetworkImage(store.imageUrl!)
                        : null,
                    child: store.imageUrl == null || store.imageUrl!.isEmpty
                        ? const Icon(Icons.store, size: 30, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    store.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(store.province),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
