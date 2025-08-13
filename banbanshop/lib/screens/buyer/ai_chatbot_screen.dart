// lib/screens/buyer/ai_chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

// [CRITICAL FIX] Add the correct import for your StoreProfileScreen
// Please verify this path matches your project structure.
import 'package:banbanshop/screens/seller/store_profile.dart';

// Data model for a store
class Store {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double rating;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.rating,
  });

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] ?? '',
      name: map['name'] ?? 'ไม่มีชื่อร้าน',
      description: map['description'] ?? 'ไม่มีรายละเอียด',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Data model for a chat message, now supporting stores
class ChatMessage {
  final String text;
  final bool isUser;
  final List<Store>? stores;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.stores,
    this.isError = false,
  });
}

class AiChatBotScreen extends StatefulWidget {
  const AiChatBotScreen({super.key});

  @override
  State<AiChatBotScreen> createState() => _AiChatBotScreenState();
}

class _AiChatBotScreenState extends State<AiChatBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'สวัสดีครับ! ผมคือผู้ช่วย AI ของ BanBanShop สามารถสอบถามเกี่ยวกับร้านค้าในแอปได้เลยครับ เช่น "หาผ้าครามที่สกลนคร" หรือ "มีร้านเครื่องจักสานแนะนำไหม"',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final HttpsCallable callable = functions.httpsCallable('searchStoresWithAI');
      final result = await callable.call<Map<String, dynamic>>({'query': text});

      final responseText = result.data['responseText']?.toString() ?? '';
      final List<dynamic> storeData = result.data['stores'] ?? [];
      final List<Store> stores = storeData.map((data) => Store.fromMap(Map<String, dynamic>.from(data))).toList();

      setState(() {
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          stores: stores.isNotEmpty ? stores : null,
        ));
      });

    } on FirebaseFunctionsException catch (e) {
      String errorMessage = 'ขออภัยค่ะ เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
      if (e.code == 'internal') {
        errorMessage = 'ขออภัยค่ะ ระบบ AI ขัดข้องชั่วคราว กรุณาลองใหม่อีกครั้ง';
      } else if (e.code == 'deadline-exceeded') {
        errorMessage = 'ขออภัยค่ะ ใช้เวลาค้นหานานเกินไป กรุณาลองใหม่อีกครั้ง';
      }
      print("Firebase Functions Error: ${e.code} - ${e.message}");
      setState(() {
        _messages.add(ChatMessage(text: errorMessage, isUser: false, isError: true));
      });
    } catch (e) {
      print("Generic Error: $e");
      setState(() {
        _messages.add(ChatMessage(text: 'ขออภัยค่ะ เกิดข้อผิดพลาดที่ไม่คาดคิด', isUser: false, isError: true));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Column(
                  crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildChatBubble(message),
                    if (message.stores != null && message.stores!.isNotEmpty)
                      ...message.stores!.map((store) => _buildStoreCard(store)).toList(),
                  ],
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0)),
                  const SizedBox(width: 12),
                  Text("AI กำลังค้นหา...", style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    if (!message.isUser && message.text.isEmpty && message.stores != null && message.stores!.isNotEmpty) {
      return const SizedBox.shrink();
    }
    
    final bool isError = message.isError;
    final Color bubbleColor = message.isUser
        ? const Color(0xFF0288D1)
        : (isError ? const Color(0xFFFFEBEE) : const Color(0xFFE0F7FA));
    final Color textColor = message.isUser
        ? Colors.white
        : (isError ? const Color(0xFFB71C1C) : Colors.black87);

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20.0).copyWith(
            bottomRight: message.isUser ? const Radius.circular(5) : const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(5),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(message.text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }

  // [CRITICAL FIX] Added Navigation logic to the correct screen
  Widget _buildStoreCard(Store store) {
    return GestureDetector(
      onTap: () {
        print("Navigating to StoreProfileScreen for ID: ${store.id}");
        Navigator.push(
          context,
          MaterialPageRoute(
            // Call the correct screen from your project
            builder: (context) => StoreProfileScreen(
              storeId: store.id,
              isSellerView: false, // Assuming the user is a buyer
            ),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: store.imageUrl.isNotEmpty
                  ? Image.network(
                      store.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 120, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                      errorBuilder: (context, error, stack) => Container(height: 120, color: Colors.grey[200], child: const Icon(Icons.storefront, color: Colors.grey, size: 50)),
                    )
                  : Container(height: 120, color: Colors.grey[200], child: const Center(child: Icon(Icons.storefront, color: Colors.grey, size: 50))),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(store.description, style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(store.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Text('ดูรายละเอียด', style: TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'ถามเกี่ยวกับร้านค้า...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                ),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              style: IconButton.styleFrom(backgroundColor: const Color(0xFF4A00E0), foregroundColor: Colors.white, padding: const EdgeInsets.all(12)),
            ),
          ],
        ),
      ),
    );
  }
}
