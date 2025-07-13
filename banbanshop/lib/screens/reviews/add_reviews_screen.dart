// lib/screens/reviews/add_review_screen.dart (ฉบับแก้ไข)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';

class AddReviewScreen extends StatefulWidget {
  final String storeId;
  final String storeName;

  const AddReviewScreen({
    super.key,
    required this.storeId,
    required this.storeName,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบเพื่อเขียนรีวิว')),
      );
      return;
    }

    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาให้คะแนนดาวอย่างน้อย 1 ดวง')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(user.uid)
          .get();
      
      if (!buyerDoc.exists) {
        throw Exception('ไม่พบข้อมูลผู้ซื้อ');
      }
      
      final buyerProfile = BuyerProfile.fromFirestore(buyerDoc);

      final reviewData = {
        'buyerId': user.uid,
        'buyerName': buyerProfile.fullName ?? 'ผู้ใช้',
        'buyerImageUrl': buyerProfile.profileImageUrl,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': Timestamp.now(),
        'storeId': widget.storeId,
      };

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('reviews')
          .add(reviewData);
    

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ขอบคุณสำหรับรีวิวของคุณ!')),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เขียนรีวิวร้าน ${widget.storeName}'),
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ให้คะแนนร้านค้า',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'เล่าประสบการณ์ของคุณเกี่ยวกับร้านค้านี้...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6ADE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'ส่งรีวิว',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}