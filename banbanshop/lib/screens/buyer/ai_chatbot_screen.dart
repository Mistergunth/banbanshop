// lib/screens/buyer/ai_chatbot_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';


class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
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

  // สร้าง instance ของ Cloud Functions
  final FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'us-central1'); 

  @override
  void initState() {
    super.initState();
    // เพิ่มข้อความต้อนรับเริ่มต้น
    _messages.add(
      ChatMessage(
        text: 'สวัสดีครับ! ผมคือผู้ช่วย AI ของ BanBanShop ยินดีให้บริการครับ',
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

  // --- [อัปเดตแล้ว] ---
  // ฟังก์ชันนี้จะเรียกใช้ Cloud Function ที่สร้างไว้แทน n8n
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
      // เรียกใช้ Cloud Function ที่ชื่อ 'chatWithGemini'
      final HttpsCallable callable = functions.httpsCallable('chatWithGemini');
      final result = await callable.call<Map<String, dynamic>>({
        'message': text, // ส่งข้อมูลในรูปแบบที่ฟังก์ชันต้องการ
      });

      // ดึงคำตอบจาก key 'reply' ที่เรากำหนดไว้ใน index.js
      final reply = result.data['reply']?.toString() ?? 'ขออภัยค่ะ ไม่สามารถประมวลผลคำตอบได้';

      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
      });

    } on FirebaseFunctionsException catch (e) {
      // จัดการกับ Error ที่มาจาก Cloud Function โดยเฉพาะ
      print("Firebase Functions Error: ${e.code} - ${e.message}");
      setState(() {
        _messages.add(ChatMessage(
          text: 'ขออภัยค่ะ เกิดข้อผิดพลาดในการเชื่อมต่อกับ AI (Code: ${e.code})',
          isUser: false,
        ));
      });
    } catch (e) {
      print("Generic Error: $e");
      setState(() {
        _messages.add(ChatMessage(
          text: 'ขออภัยค่ะ เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ',
          isUser: false,
        ));
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
    // UI ทั้งหมดเหมือนเดิมทุกประการ
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot (Firebase)'),
        backgroundColor: const Color(0xFF9C6ADE),
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
                return _buildChatBubble(message);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text("AI กำลังพิมพ์..."),
                ],
              ),
            ),
          _buildTextInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isUser ? const Color(0xFF9C6ADE) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0).copyWith(
            bottomRight: message.isUser ? const Radius.circular(5) : const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(5),
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความที่นี่...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
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
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF9C6ADE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
