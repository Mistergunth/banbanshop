import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import แพ็คเกจ image_picker
import 'dart:io'; // Import สำหรับ File
import 'package:banbanshop/screens/post_model.dart'; // Import Post model

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image; // เปลี่ยนกลับมาใช้ File? _image สำหรับรูปภาพจริง
  final TextEditingController _captionController = TextEditingController(); // Controller สำหรับข้อความแคปชั่น
  String? _selectedProvince; // สำหรับเลือกจังหวัดของโพสต์
  String? _selectedCategory; // สำหรับเลือกหมวดหมู่ของโพสต์

  final List<String> _provinces = [
    'กรุงเทพมหานคร', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น',
    'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร',
    'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก',
    'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี',
    'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์',
    'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พังงา', 'พัทลุง', 'พิจิตร',
    'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'พะเยา', 'ภูเก็ต',
    'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยะลา', 'ยโสธร', 'ร้อยเอ็ด',
    'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย',
    'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม',
    'สมุทรสาคร', 'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อุดรธานี',
    'อุทัยธานี',
    'อุตรดิตถ์',
    'อุบลราชธานี',
    'อำนาจเจริญ',
  ];

  final List<String> _categories = [
    'เสื้อผ้า', 'อาหาร & เครื่องดื่ม', 'กีฬา & กิจกรรม', 'สิ่งของเครื่องใช้'
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // ใช้ ImageSource.gallery เพื่อเลือกจากแกลเลอรี

    if (!mounted) return; // เพิ่ม mounted check

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path); // เก็บ File object
      } else {
        // print('No image selected.'); // ลบ print()
      }
    });
  }

  void _postContent() {
    if (_image == null || _captionController.text.isEmpty || _selectedProvince == null || _selectedCategory == null) {
      if (mounted) { // เพิ่ม mounted check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพ, เขียนข้อความ, เลือกจังหวัดและหมวดหมู่')),
        );
      }
      return;
    }

    // สร้าง Post object ใหม่
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // ID ชั่วคราว
      shopName: 'ผู้ใช้ปัจจุบัน', // สมมติชื่อร้านค้าของผู้ใช้ปัจจุบัน
      timeAgo: 'เมื่อสักครู่', // เวลาชั่วคราว
      category: _selectedCategory!,
      title: _captionController.text,
      imageUrl: _image!.path, // ใช้ path ของรูปภาพที่เลือกจริง
      avatarImageUrl: 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png', // รูป Avatar ชั่วคราว
      province: _selectedProvince!,
      productCategory: _selectedCategory!,
    );

    // ส่งโพสต์ใหม่กลับไปยังหน้า FeedPage
    if (mounted) { // เพิ่ม mounted check
      Navigator.pop(context, newPost);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0), // เพิ่ม padding ด้านบนสำหรับปุ่ม
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
                        ? Image.file( // ใช้ Image.file เพื่อแสดงรูปภาพจาก File object
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
                const SizedBox(height: 20),

                // Dropdown สำหรับเลือกจังหวัด
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: InputDecoration(
                    labelText: 'เลือกจังหวัด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _provinces.map((String province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedProvince = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
                ),
                const SizedBox(height: 20),

                // Dropdown สำหรับเลือกหมวดหมู่
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'เลือกหมวดหมู่',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ปุ่มกากบาท (ปิด)
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 28),
              onPressed: () {
                if (mounted) Navigator.pop(context); // เพิ่ม mounted check
              },
            ),
          ),

          // ปุ่มโพสต์
          Positioned(
            top: 40,
            right: 16,
            child: TextButton(
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
          ),
        ],
      ),
    );
  }
}
