// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, unnecessary_nullable_for_final_variable_declarations

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:banbanshop/screens/post_model.dart'; // ตรวจสอบว่า Post model อยู่ที่นี่
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
// Removed: import 'package:banbanshop/screens/profile.dart'; // Import SellerProfile (unused)
import 'package:uuid/uuid.dart'; // เพิ่มสำหรับสร้าง UUID

class CreatePostScreen extends StatefulWidget {
  final Post? initialPost; // เพิ่ม parameter สำหรับโพสต์เริ่มต้น (ถ้าเป็นการแก้ไข)

  const CreatePostScreen({super.key, this.initialPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _imageFile; // เปลี่ยนชื่อเป็น _imageFile เพื่อความชัดเจน
  final TextEditingController _captionController = TextEditingController();
  String? _selectedProvince;
  String? _selectedCategory; // นี่คือ productCategory ใน Post model
  bool _isUploading = false; // สถานะการอัปโหลด
  String? _existingImageUrl; // เก็บ URL รูปภาพเดิมเมื่ออยู่ในโหมดแก้ไข

  // Default avatar URL
  static const String _defaultAvatarUrl = 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png';

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

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      // ถ้าเป็นการแก้ไขโพสต์ ให้กำหนดค่าเริ่มต้นจาก initialPost
      _captionController.text = widget.initialPost!.title;
      _selectedProvince = widget.initialPost!.province;
      _selectedCategory = widget.initialPost!.productCategory; // ใช้ productCategory
      _existingImageUrl = widget.initialPost!.imageUrl; // เก็บ URL รูปภาพเดิม
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (!mounted) return;

    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
        _existingImageUrl = null; // เมื่อเลือกรูปใหม่ ให้ลบ URL รูปภาพเดิมออก
      } else {
        // print('No image selected.');
      }
    });
  }

  void _submitContent() async { // เปลี่ยนชื่อเป็น _submitContent เพื่อให้ครอบคลุมทั้งสร้างและแก้ไข
    // ตรวจสอบว่าข้อมูลที่จำเป็นครบถ้วนหรือไม่
    if (_imageFile == null && _existingImageUrl == null) { // ต้องมีรูปภาพอย่างน้อยหนึ่งรูป
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกรูปภาพสำหรับโพสต์')),
        );
      }
      return;
    }
    if (_captionController.text.isEmpty || _selectedProvince == null || _selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเขียนข้อความ, เลือกจังหวัดและหมวดหมู่ให้ครบถ้วน')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true; // เริ่มโหลด
    });

    String? finalImageUrl = _existingImageUrl; // เริ่มต้นด้วยรูปภาพเดิม
    final User? currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณต้องเข้าสู่ระบบเพื่อสร้าง/แก้ไขโพสต์')),
        );
      }
      setState(() {
        _isUploading = false;
      });
      return;
    }

    String shopName = 'ไม่ระบุชื่อร้าน';
    String finalAvatarImageUrl = _defaultAvatarUrl; // กำหนดค่าเริ่มต้นเป็นรูป Default เสมอ
    String ownerUid = currentUser.id;

    try {
      final SupabaseClient supabaseClient = Supabase.instance.client; // Get client instance
      final dynamic sellerDataRaw = await supabaseClient
          .from('sellers')
          .select('full_name, profile_image_url') // Select เฉพาะคอลัมน์ที่ต้องการ
          .eq('id', currentUser.id)
          .maybeSingle(); // ใช้ maybeSingle เพื่อให้ได้ null ถ้าไม่พบข้อมูล

      if (sellerDataRaw != null) {
        final Map<String, dynamic> sellerData = sellerDataRaw as Map<String, dynamic>; // Explicit cast here
        // แก้ไข: ดึงข้อมูลโดยตรงจาก Map ที่เป็น snake_case
        shopName = (sellerData['full_name'] as String?)?.isNotEmpty == true
            ? sellerData['full_name'] as String
            : 'ไม่ระบุชื่อร้าน';
        finalAvatarImageUrl = (sellerData['profile_image_url'] as String?) ?? _defaultAvatarUrl;
      } else {
        print('Seller profile not found for user: $ownerUid. Using default name and avatar.');
      }
    } catch (e) {
      print('Error fetching seller profile for post: $e');
      // ไม่ต้องแสดง SnackBar เพราะเป็นแค่ข้อมูลเสริม และมีค่า default รองรับแล้ว
    }

    // จัดการการอัปโหลด/เปลี่ยนรูปภาพ
    if (_imageFile != null) { // ถ้ามีการเลือกรูปภาพใหม่
      try {
        // ถ้ามีรูปภาพเดิมอยู่ ให้ลบรูปภาพเดิมออกจาก Storage ก่อน
        if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
          try {
            final Uri uri = Uri.parse(_existingImageUrl!);
            // ดึง full path ใน bucket (เช่น user_id/filename.jpg)
            final String fullPathInBucket = uri.path.substring(uri.path.indexOf('/posts.images/') + '/posts.images/'.length);
            await Supabase.instance.client.storage.from('posts.images').remove([fullPathInBucket]);
            print('Old image removed from storage: $fullPathInBucket');
          } catch (e) {
            print('Error removing old image from storage: $e');
            // ไม่ต้อง throw error เพราะอาจจะไม่มีรูปเดิม หรือลบไม่สำเร็จแต่ยังสามารถอัปโหลดรูปใหม่ได้
          }
        }

        final String imageFileName = '${const Uuid().v4()}.jpg';
        final String storagePath = '${currentUser.id}/$imageFileName';
        final String bucketName = 'posts.images';

        // Supabase upload returns a path string on success
        final String? publicUrl = Supabase.instance.client.storage
            .from(bucketName)
            .getPublicUrl(storagePath); // Get public URL before uploading

        if (publicUrl == null || publicUrl.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('อัปโหลดรูปภาพไม่สำเร็จ: ไม่สามารถรับ URL ได้')),
            );
          }
          setState(() { _isUploading = false; });
          return;
        }

        // Now upload the file
        await Supabase.instance.client.storage
            .from(bucketName)
            .upload(
              storagePath,
              _imageFile!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
            );

        finalImageUrl = publicUrl; // ใช้ publicUrl ที่ได้มา

      } on StorageException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ (Storage): ${e.message}')),
          );
        }
        setState(() { _isUploading = false; });
        return;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิดในการอัปโหลดรูปภาพ: $e')),
          );
        }
        setState(() { _isUploading = false; });
        return;
      }
    }

    // สร้าง Post object
    final Post postToSave = Post(
      id: widget.initialPost?.id ?? const Uuid().v4(), // ใช้ ID เดิมถ้าเป็นการแก้ไข, ไม่งั้นสร้างใหม่
      createdAt: widget.initialPost?.createdAt ?? DateTime.now(), // ใช้เวลาเดิมถ้าเป็นการแก้ไข, ไม่งั้นใช้เวลาปัจจุบัน
      shopName: shopName,
      category: _selectedCategory!,
      title: _captionController.text.trim(),
      imageUrl: finalImageUrl, // ใช้ URL รูปภาพสุดท้าย
      avatarImageUrl: finalAvatarImageUrl, // ใช้ URL รูปโปรไฟล์สุดท้าย (มี Default แล้ว)
      province: _selectedProvince!,
      productCategory: _selectedCategory!,
      ownerUid: ownerUid,
    );

    // บันทึกข้อมูลโพสต์ลงใน Supabase
    try {
      if (widget.initialPost == null) {
        // ถ้าเป็นโพสต์ใหม่ (initialPost เป็น null) ให้ INSERT
        await Supabase.instance.client.from('posts').insert(postToSave.toJson());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('สร้างโพสต์สำเร็จ!')),
          );
        }
      } else {
        // ถ้าเป็นการแก้ไขโพสต์ (initialPost ไม่เป็น null) ให้ UPDATE
        await Supabase.instance.client
            .from('posts')
            .update(postToSave.toJson())
            .eq('id', postToSave.id); // อัปเดตโดยใช้ ID ของโพสต์
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('แก้ไขโพสต์สำเร็จ!')),
          );
        }
      }
      if (mounted) {
        Navigator.pop(context, postToSave); // ส่งโพสต์ที่ถูกบันทึก/แก้ไขกลับไป
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก/แก้ไขโพสต์: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
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
                    child: _imageFile != null // มีรูปใหม่ที่เลือก
                        ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          )
                        : _existingImageUrl != null && _existingImageUrl!.isNotEmpty // มีรูปเดิมจากโพสต์
                            ? Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
                                ),
                              )
                            : Column( // ไม่มีรูปเลย
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

                // ส่วนสำหรับเขียนข้อความ/แคปชั่น (ชื่อโพสต์)
                TextField(
                  controller: _captionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'เขียนแคปชั่น (ชื่อโพสต์)...',
                    border: InputBorder.none, // Changed from BorderSide.none to InputBorder.none
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
                    border: InputBorder.none, // Changed from BorderSide.none to InputBorder.none
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

                // Dropdown สำหรับเลือกหมวดหมู่ (productCategory)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'เลือกหมวดหมู่สินค้า', // เปลี่ยน label
                    border: InputBorder.none, // Changed from BorderSide.none to InputBorder.none
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
                  validator: (value) => value == null ? 'กรุณาเลือกหมวดหมู่สินค้า' : null,
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
                if (mounted) Navigator.pop(context);
              },
            ),
          ),

          // ปุ่มโพสต์/แก้ไข
          Positioned(
            top: 40,
            right: 16,
            child: _isUploading
                ? const CircularProgressIndicator(color: Color(0xFF9C6ADE)) // แสดง Loading Indicator
                : TextButton(
                    onPressed: _submitContent, // เรียกใช้ _submitContent
                    child: Text(
                      widget.initialPost == null ? 'โพสต์' : 'บันทึกการแก้ไข', // เปลี่ยนข้อความตามโหมด
                      style: const TextStyle(
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