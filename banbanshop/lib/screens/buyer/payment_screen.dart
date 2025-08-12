// lib/screens/buyer/payment_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/models/order_model.dart' as app_order;

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final String storeId;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.storeId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Store? _store;
  app_order.Order? _order;
  bool _isLoading = true;
  bool _isConfirming = false;
  File? _slipImageFile;

  final Cloudinary cloudinary = Cloudinary.full(
    cloudName: 'dbgybkvms', 
    apiKey: '157343641351425', 
    apiSecret: 'uXRJ6lo7O24Qqdi_kqANJisGZgU', 
  );
  final String uploadPreset = 'flutter_unsigned_upload';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final storeFuture = FirebaseFirestore.instance.collection('stores').doc(widget.storeId).get();
      final orderFuture = FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final results = await Future.wait([storeFuture, orderFuture]);
      
      final storeDoc = results[0] as DocumentSnapshot;
      final orderDoc = results[1] as DocumentSnapshot;

      if (mounted) {
        setState(() {
          if (storeDoc.exists) {
            _store = Store.fromFirestore(storeDoc);
          }
          if (orderDoc.exists) {
            _order = app_order.Order.fromFirestore(orderDoc);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  Future<void> _pickSlipImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _slipImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_slipImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาอัปโหลดสลิปการโอนเงิน')),
      );
      return;
    }
    if (_order == null) return;

    setState(() => _isConfirming = true);

    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: _slipImageFile!.path,
          resourceType: CloudinaryResourceType.image,
          folder: 'payment_slips',
          uploadPreset: uploadPreset,
        ),
      );

      if (!response.isSuccessful || response.secureUrl == null) {
        throw 'อัปโหลดสลิปไม่สำเร็จ: ${response.error}';
      }
      final slipUrl = response.secureUrl!;

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('orders')
          .doc(widget.orderId)
          .update({
            'status': app_order.OrderStatus.processing.toString().split('.').last,
            'paymentSlipUrl': slipUrl,
          });

      final cartCollection = FirebaseFirestore.instance
          .collection('buyers')
          .doc(_order!.buyerId)
          .collection('cart');
      
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final orderItem in _order!.items) {
        final cartItemRef = cartCollection.doc(orderItem.productId);
        batch.delete(cartItemRef);
      }
      await batch.commit();

      if (mounted) {
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('แจ้งชำระเงินสำเร็จ'),
              content: const Text('ร้านค้าจะทำการตรวจสอบและดำเนินการจัดส่งโดยเร็วที่สุด'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ตกลง'),
                ),
              ],
            ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
          : _store == null || _order == null || _store!.paymentInfo == null
              ? const Center(child: Text('ไม่พบข้อมูลการชำระเงินของร้านค้า'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPaymentDetailsCard(),
                      const SizedBox(height: 24),
                      _buildUploadSlipSection(),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  Widget _buildPaymentDetailsCard() {
    final paymentInfo = _store!.paymentInfo!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'สแกน QR Code เพื่อชำระเงิน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // Darker text
            ),
            const SizedBox(height: 16),
            if (paymentInfo['qrCodeImageUrl'] != null)
              Image.network(
                paymentInfo['qrCodeImageUrl'],
                height: 250,
                width: 250,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: const Color(0xFF0288D1), // Blue loading
                    ),
                  );
                },
                errorBuilder: (c, e, s) => const Icon(Icons.error, size: 50, color: Colors.redAccent), // Red error icon
              ),
            const SizedBox(height: 16),
            Text(
              'ยอดที่ต้องชำระ: ฿${_order!.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A00E0)), // Dark Purple amount
            ),
            const Divider(height: 32),
            _buildInfoRow('ชื่อบัญชี:', paymentInfo['accountName'] ?? 'N/A'),
            _buildInfoRow('ธนาคาร:', paymentInfo['bankName'] ?? 'N/A'),
            _buildInfoRow('เลขที่บัญชี:', paymentInfo['accountNumber'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])), // Darker grey
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)), // Darker text
        ],
      ),
    );
  }

  Widget _buildUploadSlipSection() {
    return Column(
      children: [
        const Text('อัปโหลดสลิปการโอนเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickSlipImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), // Lighter grey border
            ),
            child: _slipImageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_slipImageFile!, fit: BoxFit.contain),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text('แตะเพื่อเลือกรูปภาพ', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _isConfirming ? null : _confirmPayment,
        icon: _isConfirming
            ? const SizedBox.shrink()
            : const Icon(Icons.check_circle_outline),
        label: _isConfirming
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
            : const Text('แจ้งชำระเงินแล้ว'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0288D1), // Blue confirm button
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold ,fontFamily: GoogleFonts.kanit().fontFamily),
        ),
      ),
    );
  }
}
