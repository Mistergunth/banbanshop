// lib/screens/auth/buyer_register_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:banbanshop/screens/auth/buyer_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class BuyerRegisterScreen extends StatefulWidget {
  const BuyerRegisterScreen({super.key});

  @override
  State<BuyerRegisterScreen> createState() => _BuyerRegisterScreenState();
}

class _BuyerRegisterScreenState extends State<BuyerRegisterScreen> {
  // --- API Configuration (Visai.ai) ---
  final String _apiKey = '1704b23b84937d7be4a1a7e82839e010'; 
  final String _apiUrl = 'https://ocridcard.infer.visai.ai/predict';

  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _phoneFieldKey = GlobalKey<FormFieldState>();
  final _auth = FirebaseAuth.instance;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _idCardController = TextEditingController(); // <--- เพิ่ม Controller สำหรับบัตรประชาชน

  // --- OCR State Variables ---
  String? _extractedFullName;
  String? _extractedIdNumber; // <--- เพิ่ม State สำหรับเลขบัตร
  bool _isScanning = false;

  String? _selectedProvince;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;

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
    'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย',
    'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู',
    'อ่างทอง', 'อุดรธานี', 'อุทัยธานี', 'อุตรดิตถ์', 'อุบลราชธานี', 'อำนาจเจริญ'
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _idCardController.dispose(); // <--- อย่าลืม dispose
    super.dispose();
  }

  Future<void> _scanAndProcessIdCard() async {
    final source = await _showImageSourceActionSheet();
    if (source == null) return;

    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source, imageQuality: 100);

    if (pickedFile == null) return;

    setState(() => _isScanning = true);

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.headers['X-API-Key'] = _apiKey;
      
      final mimeTypeData = lookupMimeType(pickedFile.path, headerBytes: [0xFF, 0xD8])?.split('/');
      final imageFile = await http.MultipartFile.fromPath(
        'files',
        pickedFile.path,
        contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,
      );
      request.files.add(imageFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("--- Visai API Full Response (Buyer) ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");
      print("---------------------------------------");

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(responseBody);
        if (responseData.isEmpty) {
          throw Exception('API returned an empty response.');
        }
        final data = responseData[0];
        
        if (data['status'] == 'success' && data['data'] != null) {
          final fields = data['data']['fields'];
          final fullName = fields['th_name']?['text'];
          final idNumber = fields['idnum']?['text']; // <--- ดึงเลขบัตร

          if (fullName != null && idNumber != null) { // <--- เช็คทั้งสองค่า
            setState(() {
              _extractedFullName = fullName;
              _extractedIdNumber = idNumber; // <--- ตั้งค่า State
              _fullNameController.text = fullName;
              _idCardController.text = idNumber.replaceAll(' ', ''); // <--- ตั้งค่า Controller
            });
            _formKey.currentState?.validate();
          } else {
            List<String> missingFields = [];
            if (idNumber == null) missingFields.add("เลขบัตร (idnum)");
            if (fullName == null) missingFields.add("ชื่อไทย (th_name)");
            throw Exception('ไม่พบข้อมูลสำคัญ: ${missingFields.join(', ')}');
          }
        } else {
          throw Exception(data['message'] ?? 'API returned an error.');
        }
      } else {
        throw Exception('API Error: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการสแกน', e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _showErrorDialog(String title, String content) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SelectableText(content),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ปิด'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<ImageSource?> _showImageSourceActionSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_emailFieldKey.currentState!.validate() || !_phoneFieldKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final phoneNumber = "+66${_phoneController.text.trim()}";

      final List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        final sellerDoc = await FirebaseFirestore.instance.collection('sellers').where('email', isEqualTo: email).limit(1).get();
        if (sellerDoc.docs.isNotEmpty) {
          throw FirebaseAuthException(code: 'email-already-in-use-as-seller');
        }
        throw FirebaseAuthException(code: 'email-already-in-use');
      }

      final sellerPhoneDoc = await FirebaseFirestore.instance.collection('sellers').where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
      if (sellerPhoneDoc.docs.isNotEmpty) {
        throw FirebaseAuthException(code: 'phone-already-in-use-as-seller');
      }

      print("[REG] Email and Phone are available for buyer registration. Proceeding with phone verification...");

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
           if(mounted) setState(() => _isLoading = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("เกิดข้อผิดพลาดในการส่ง OTP: ${e.message}")),
          );
          if (mounted) setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP ได้ถูกส่งไปยังเบอร์โทรศัพท์ของคุณแล้ว')),
          );
          setState(() {
            _isOtpSent = true;
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
       String message = 'เกิดข้อผิดพลาดในการส่ง OTP';
       if (e.code == 'email-already-in-use') {
         message = 'อีเมลนี้ถูกใช้งานแล้วในฐานะผู้ซื้อ กรุณาเข้าสู่ระบบ';
       } else if (e.code == 'email-already-in-use-as-seller') {
         message = 'อีเมลนี้ถูกใช้งานแล้วในฐานะผู้ขาย กรุณาเข้าสู่ระบบในฐานะผู้ขาย';
       } else if (e.code == 'phone-already-in-use-as-seller') {
         message = 'เบอร์โทรศัพท์นี้ถูกใช้งานแล้วในฐานะผู้ขาย กรุณาเข้าสู่ระบบในฐานะผู้ขาย';
       } else {
          message = 'เกิดข้อผิดพลาด: ${e.message}';
       }
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
       }
       if (mounted) setState(() => _isLoading = false);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
        );
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _registerBuyer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpSent || _verificationId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดส่งและยืนยัน OTP ก่อน')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Phone auth failed, user is null.");
      }

      final existingSellerDoc = await FirebaseFirestore.instance.collection('sellers').doc(user.uid).get();
      if (existingSellerDoc.exists) {
        await FirebaseAuth.instance.signOut();
        throw FirebaseAuthException(code: 'uid-already-in-use-as-seller');
      }

      final emailCredential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await user.linkWithCredential(emailCredential);
      
      await user.updateProfile(displayName: _fullNameController.text.trim());
      
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('buyers').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': "+66${_phoneController.text.trim()}",
        'province': _selectedProvince,
        'idCardNumber': _idCardController.text.trim(), // <--- บันทึกเลขบัตร
        'createdAt': Timestamp.now(),
        'isPhoneVerified': true,
      });

    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
      if (e.code == 'weak-password') {
        message = 'รหัสผ่านคาดเดาง่ายเกินไป';
      } else if (e.code == 'invalid-credential' || e.code == 'credential-already-in-use'){
        message = 'ข้อมูลรับรองไม่ถูกต้องหรือถูกใช้งานแล้ว';
      } else if (e.code == 'invalid-verification-code') {
        message = 'รหัส OTP ไม่ถูกต้อง';
      } else if (e.code == 'uid-already-in-use-as-seller') {
        message = 'บัญชีนี้ถูกใช้งานแล้วในฐานะผู้ขาย กรุณาเข้าสู่ระบบในฐานะผู้ขาย';
      }
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดที่ไม่คาดคิด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บ้านบ้านช็อป', style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Color(0xFFE8F4FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ผู้ซื้อ - สมัครสมาชิก', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                _buildOcrSection(),

                const SizedBox(height: 15),
                _buildInputField(
                  fieldKey: _emailFieldKey,
                  label: 'อีเมล', 
                  controller: _emailController, 
                  keyboardType: TextInputType.emailAddress, 
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'รูปแบบอีเมลไม่ถูกต้อง';
                    return null;
                  }
                ),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInputField(
                        fieldKey: _phoneFieldKey,
                        label: 'เบอร์โทรศัพท์',
                        subLabel: '(ไม่ต้องใส่ 0 นำหน้า)',
                        controller: _phoneController,
                        prefixText: '+66 ',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณากรอกเบอร์โทร';
                          if (v.length != 9) return 'ต้องมี 9 หลัก';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 44.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: Text(_isOtpSent ? 'ส่งอีกครั้ง' : 'ส่ง OTP'),
                      ),
                    )
                  ],
                ),
                if (_isOtpSent) ...[
                  const SizedBox(height: 15),
                  _buildInputField(
                    label: 'รหัส OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'กรุณากรอก OTP' : null,
                  ),
                ],
                const SizedBox(height: 15),
                _buildProvinceDropdown(),
                const SizedBox(height: 15),
                _buildPasswordField(label: 'รหัสผ่าน', controller: _passwordController, isVisible: _isPasswordVisible, onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible), validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                  if (v.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                  return null;
                }),
                const SizedBox(height: 15),
                _buildPasswordField(label: 'ยืนยันรหัสผ่าน', controller: _confirmPasswordController, isVisible: _isConfirmPasswordVisible, onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible), validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                  if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                }),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerBuyer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('สมัครสมาชิก', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('มีบัญชีอยู่แล้ว?', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyerLoginScreen())),
                      child: const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9B7DD9))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOcrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ข้อมูลจากบัตรประชาชน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: Colors.grey[300]!)
          ),
          child: Column( // <--- เปลี่ยนเป็น Column
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ชื่อ-นามสกุล:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _extractedFullName ?? 'ยังไม่ได้สแกน',
                      textAlign: TextAlign.end,
                      style: TextStyle(color: _extractedFullName == null ? Colors.red : Colors.black87, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 1), // <--- เพิ่มเส้นคั่น
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('เลขบัตรประชาชน:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _extractedIdNumber ?? 'ยังไม่ได้สแกน',
                      textAlign: TextAlign.end,
                       style: TextStyle(color: _extractedIdNumber == null ? Colors.red : Colors.black87, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'แนะนำ: ถ่ายภาพให้ชัดเจน ไม่มีแสงสะท้อน',
                  style: TextStyle(color: Colors.orange[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanAndProcessIdCard,
            icon: _isScanning 
                ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Icon(Icons.camera_alt, color: Colors.white),
            label: Text(_isScanning ? 'กำลังสแกน...' : 'สแกน/อัปโหลดรูปบัตร', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5C6BC0), // Indigo
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            ),
          ),
        ),
        TextFormField(
          readOnly: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            constraints: BoxConstraints(maxHeight: 0),
          ),
          validator: (value) {
            if (_fullNameController.text.isEmpty) {
              return 'กรุณาสแกนบัตรประชาชนเพื่อดึงข้อมูล';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    String? subLabel,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    Key? fieldKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        if (subLabel != null) ...[
          const SizedBox(height: 2),
          Text(subLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixText: prefixText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool isVisible, required VoidCallback onToggleVisibility, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildProvinceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('จังหวัด', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          hint: const Text('เลือกจังหวัด'),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          items: _provinces.map((String province) => DropdownMenuItem<String>(value: province, child: Text(province))).toList(),
          onChanged: (String? newValue) => setState(() => _selectedProvince = newValue),
          validator: (value) => value == null ? 'กรุณาเลือกจังหวัด' : null,
        ),
      ],
    );
  }
}
