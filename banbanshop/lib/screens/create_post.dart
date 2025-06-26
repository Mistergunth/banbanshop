import 'package:flutter/material.dart';// จำลองการใช้ image_picker
import 'dart:io'; // สำหรับ File

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image; // ตัวแปรสำหรับเก็บรูปภาพที่เลือก
  final TextEditingController _captionController = TextEditingController(); // Controller สำหรับข้อความแคปชั่น

  // ฟังก์ชันสำหรับเลือกรูปภาพ
  Future<void> _pickImage() async {
    // ในสถานการณ์จริง คุณจะใช้ ImagePicker.pickImage
    // แต่ในสภาพแวดล้อมนี้ เราจะจำลองการเลือกรูปภาพ
    // หากคุณรันบนอุปกรณ์จริง สามารถใช้โค้ดด้านล่างนี้ได้
    /*
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
    */

    // จำลองการเลือกรูปภาพด้วยการใช้ NetworkImage ชั่วคราว
    // ในแอปจริง คุณจะแสดงรูปภาพที่ผู้ใช้เลือก
    setState(() {
      // ตัวอย่าง URL รูปภาพชั่วคราว
      _image = null; // เคลียร์รูปเก่า
      // หากต้องการแสดงรูปภาพที่เลือกจริง ต้องใช้ image_picker และ File
      // สำหรับการสาธิตนี้ เราจะแค่แสดงข้อความว่าเลือกรูปแล้ว
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำลอง: เลือกรูปภาพแล้ว')),
      );
    });
  }

  // ฟังก์ชันสำหรับโพสต์
  void _postContent() {
    if (_image == null && _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรูปภาพหรือเขียนข้อความ')),
      );
      return;
    }

    // TODO: Implement actual post logic (e.g., upload to server, save to database)
    print('Posting...');
    print('Caption: ${_captionController.text}');
    print('Image selected: ${_image != null ? "Yes" : "No"}');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('โพสต์สำเร็จ!')),
    );

    // กลับไปยังหน้าฟีดหลังจากโพสต์
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: _postContent,
            child: const Text(
              'โพสต์',
              style: TextStyle(
                color: Color(0xFF9C6ADE),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ส่วนสำหรับเลือกรูปภาพ
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: _image != null
                    ? Image.file(
                        _image!,
                        fit: BoxFit.cover,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey[600]),
                          const SizedBox(height: 10),
                          Text(
                            'แตะเพื่อเลือกรูปภาพ',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ส่วนสำหรับเขียนข้อความ/แคปชั่น
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'เขียนแคปชั่น...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.all(16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
