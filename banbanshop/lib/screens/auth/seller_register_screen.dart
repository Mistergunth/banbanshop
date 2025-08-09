// lib/screens/auth/seller_register_screen.dart

// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SellerRegisterScreen extends StatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState>();
  final _phoneFieldKey = GlobalKey<FormFieldState>();
  final _auth = FirebaseAuth.instance;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  String? _selectedProvince;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String _scanStatusMessage = 'สแกน/อัปโหลดบัตรประชาชน';

  bool _isOtpSent = false;
  String? _verificationId;
  int? _resendToken;

  StreamSubscription<DocumentSnapshot>? _scanSubscription;
  String? _scanId;

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
    _idCardController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _scanSubscription?.cancel();
    super.dispose();
  }


  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูปใหม่'),
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

  // [REWRITTEN] This function now uploads the image and listens for results from Firestore.
  Future<void> _scanIdCard() async {
    // Cancel any previous listener
    await _scanSubscription?.cancel();

    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่ได้เลือกรูปภาพ')));
      return;
    }

    setState(() {
      _isLoading = true;
      _scanStatusMessage = 'กำลังอัปโหลด...';
    });

    // 1. Generate a unique ID for this scan session
    _scanId = const Uuid().v4();
    final imageFile = File(image.path);
    final storagePath = 'id_card_images/$_scanId.jpg';

    try {
      // 2. Upload the image to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putFile(imageFile);
      print('Image uploaded successfully to: $storagePath');

      setState(() {
        _scanStatusMessage = 'กำลังประมวลผลภาพ...';
      });

      // 3. Listen for the result from the Cloud Function in Firestore
      final docRef = FirebaseFirestore.instance.collection('idCardScans').doc(_scanId);
      _scanSubscription = docRef.snapshots().timeout(const Duration(seconds: 60), onTimeout: (sink) {
        sink.addError('หมดเวลาในการประมวลผล กรุณาลองอีกครั้ง');
      }).listen(
        (snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            final status = data['status'];

            if (status == 'completed') {
              setState(() {
                _fullNameController.text = data['fullName'] ?? '';
                _idCardController.text = data['idNumber'] ?? '';
                _isLoading = false;
                _scanStatusMessage = 'สแกนข้อมูลสำเร็จ!';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('สแกนข้อมูลสำเร็จ กรุณาตรวจสอบความถูกต้อง')),
              );
              _scanSubscription?.cancel();
            } else if (status == 'error') {
              final errorMessage = data['errorMessage'] ?? 'เกิดข้อผิดพลาดในการประมวลผล';
              throw Exception(errorMessage);
            }
          }
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            _scanStatusMessage = 'เกิดข้อผิดพลาด ลองอีกครั้ง';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ข้อผิดพลาด: ${error.toString()}')),
          );
          _scanSubscription?.cancel();
        }
      );

    } catch (e) {
      setState(() {
        _isLoading = false;
        _scanStatusMessage = 'อัปโหลดล้มเหลว ลองอีกครั้ง';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e')),
      );
    }
  }


  Future<void> _sendOtp() async {
    // Validate email and phone fields first
    if (!_emailFieldKey.currentState!.validate() || !_phoneFieldKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final phoneNumber = "+66${_phoneController.text.trim()}";

      // [NEW] Check if email is already in use by ANY Firebase Auth user
      final List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        // If email is already registered, check if it's already a buyer
        final buyerDoc = await FirebaseFirestore.instance.collection('buyers').where('email', isEqualTo: email).limit(1).get();
        if (buyerDoc.docs.isNotEmpty) {
          throw FirebaseAuthException(code: 'email-already-in-use-as-buyer'); // Custom error code
        }
        // If it's not a buyer, it must be a seller (or linked to phone auth)
        throw FirebaseAuthException(code: 'email-already-in-use');
      }

      // [NEW] Check if phone number is already registered as a buyer
      final buyerPhoneDoc = await FirebaseFirestore.instance.collection('buyers').where('phoneNumber', isEqualTo: phoneNumber).limit(1).get();
      if (buyerPhoneDoc.docs.isNotEmpty) {
        throw FirebaseAuthException(code: 'phone-already-in-use-as-buyer'); // Custom error code
      }

      print("[REG] Email and Phone are available for seller registration. Proceeding with phone verification...");

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
         message = 'อีเมลนี้ถูกใช้งานแล้วในฐานะผู้ขาย กรุณาเข้าสู่ระบบ';
       } else if (e.code == 'email-already-in-use-as-buyer') { // [NEW] Custom error
         message = 'อีเมลนี้ถูกใช้งานแล้วในฐานะผู้ซื้อ กรุณาเข้าสู่ระบบในฐานะผู้ซื้อ';
       } else if (e.code == 'phone-already-in-use-as-buyer') { // [NEW] Custom error
         message = 'เบอร์โทรศัพท์นี้ถูกใช้งานแล้วในฐานะผู้ซื้อ กรุณาเข้าสู่ระบบในฐานะผู้ซื้อ';
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

  void _registerSeller() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpSent || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดส่งและยืนยัน OTP ก่อน')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Step 1: Sign in with phone credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Phone auth failed, user is null.");
      }

      // [NEW] Check if this UID already exists in 'buyers' collection
      final existingBuyerDoc = await FirebaseFirestore.instance.collection('buyers').doc(user.uid).get();
      if (existingBuyerDoc.exists) {
        // If the UID already has a buyer profile, prevent creating a seller profile
        await FirebaseAuth.instance.signOut(); // Sign out to prevent mixed state
        throw FirebaseAuthException(code: 'uid-already-in-use-as-buyer'); // Custom error code
      }

      // Step 2: Link with email credential
      final emailCredential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await user.linkWithCredential(emailCredential);
      
      // Step 3: Update profile
      await user.updateProfile(displayName: _fullNameController.text.trim());
      
      // Step 4: Send verification email
      await user.sendEmailVerification();

      // Step 5: Save user data to Firestore
      await FirebaseFirestore.instance.collection('sellers').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': "+66${_phoneController.text.trim()}",
        'idCardNumber': _idCardController.text.trim(),
        'province': _selectedProvince,
        'hasStore': false,
        'createdAt': Timestamp.now(),
        'idCardScanId': _scanId,
      });

    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาดในการสมัครสมาชิก';
      if (e.code == 'weak-password') {
        message = 'รหัสผ่านคาดเดาง่ายเกินไป';
      } else if (e.code == 'invalid-credential' || e.code == 'credential-already-in-use'){
        message = 'ข้อมูลรับรองไม่ถูกต้องหรือถูกใช้งานแล้ว';
      } else if (e.code == 'invalid-verification-code') {
        message = 'รหัส OTP ไม่ถูกต้อง';
      } else if (e.code == 'uid-already-in-use-as-buyer') { // [NEW] Custom error
        message = 'บัญชีนี้ถูกใช้งานแล้วในฐานะผู้ซื้อ กรุณาเข้าสู่ระบบในฐานะผู้ซื้อ';
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
        title: const Text('บ้านบ้านช็อป', style: 
        TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Color(0xFFE8F4FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
                const Text('ผู้ขาย - สมัครสมาชิก', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

              const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_outlined),
                    label: Text(_scanStatusMessage),
                    onPressed: _isLoading ? null : _scanIdCard,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF9B7DD9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildInputField(
                  label: 'ชื่อ - นามสกุล (จากการสแกน)', 
                  controller: _fullNameController,
                  readOnly: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'กรุณาสแกนบัตรประชาชน' : null,
                ),
                const SizedBox(height: 15),
                 _buildInputField(
                  label: 'บัตรประชาชน (จากการสแกน)', 
                  controller: _idCardController, 
                  readOnly: true,
                  keyboardType: TextInputType.number, 
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)], 
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'กรุณาสแกนบัตรประชาชน';
                    if (v.length != 13) return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                    return null;
                  }
                ),

                const SizedBox(height: 20),
                _buildInputField(label: 'ชื่อ - นามสกุล', controller: _fullNameController, validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกชื่อ';
                  if (!RegExp(r'^[a-zA-Z\u0E00-\u0E7F\s]+$').hasMatch(v)) return 'ชื่อต้องเป็นตัวอักษรเท่านั้น';
                  return null;
                }),
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
                const SizedBox(height: 15),
                _buildInputField(label: 'บัตรประชาชน', controller: _idCardController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)], validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกเลขบัตรประชาชน';
                  if (v.length != 13) return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                  return null;
                }),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerSeller,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B7DD9),
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
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerLoginScreen())),
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

  Widget _buildInputField({
    required String label,
    String? subLabel,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    Key? fieldKey,
    bool readOnly = false,
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
          readOnly: readOnly,
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
        const Text('จังหวัดที่ตั้งร้าน', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
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
