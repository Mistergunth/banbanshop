// lib/screens/reviews/store_reviews_screen.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/reviews/add_reviews_screen.dart';

// Model สำหรับ Review
class Review {
  final String id;
  final String buyerName;
  final String? buyerImageUrl;
  final double rating;
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.buyerName,
    this.buyerImageUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      buyerName: data['buyerName'] ?? 'ผู้ใช้',
      buyerImageUrl: data['buyerImageUrl'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}


class StoreReviewsScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final bool isSellerView; // <-- 1. เพิ่มพารามิเตอร์ใหม่

  const StoreReviewsScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.isSellerView = false, // <-- 2. กำหนดค่าเริ่มต้น
  });

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  void _navigateToAddReview() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อเขียนรีวิว')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          storeId: widget.storeId,
          storeName: widget.storeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('รีวิวร้าน ${widget.storeName}'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final reviews = snapshot.data!.docs
              .map((doc) => Review.fromFirestore(doc))
              .toList();
          
          double averageRating = 0;
          if (reviews.isNotEmpty) {
            averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          }

          return Column(
            children: [
              _buildSummaryHeader(averageRating, reviews.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return ReviewCard(review: reviews[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      // --- 3. เพิ่มเงื่อนไขในการแสดงผลปุ่ม ---
      floatingActionButton: (widget.isSellerView || user == null)
          ? null // ถ้าเป็นผู้ขาย หรือยังไม่ได้ล็อคอิน -> ไม่ต้องแสดงปุ่ม
          : FloatingActionButton.extended(
              onPressed: _navigateToAddReview,
              label: const Text('เขียนรีวิว'),
              icon: const Icon(Icons.edit),
              backgroundColor: const Color(0xFF9C6ADE),
            ),
    );
  }

  Widget _buildSummaryHeader(double averageRating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C6ADE),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < averageRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                'จาก $reviewCount รีวิว',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีรีวิวสำหรับร้านค้านี้',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const Text(
            'เป็นคนแรกที่รีวิวร้านค้านี้สิ!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: review.buyerImageUrl != null
                      ? NetworkImage(review.buyerImageUrl!)
                      : null,
                  child: review.buyerImageUrl == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.buyerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review.rating.round() ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.yMMMd('th').format(review.createdAt.toDate()),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}
