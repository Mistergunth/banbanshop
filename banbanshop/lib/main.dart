import 'package:banbanshop/screens/auth/seller_login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'screens/buyer/province_selection.dart';
import 'package:google_fonts/google_fonts.dart';


Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();

      // ตั้งค่า Supabase Client
      await Supabase.initialize(
        url: 'https://rmchekxyeiretdkvykwk.supabase.co', // แทนที่ด้วย Project URL ของคุณ
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtY2hla3h5ZWlyZXRka3Z5a3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NjY5MTIsImV4cCI6MjA2NzE0MjkxMn0.1Z5HWyhC15R3AbUThsFqJPBoosVES58bU18gMZGhSIY', // แทนที่ด้วย Public Key ของคุณ
      );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช้อป',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.kanit().fontFamily,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'บ้านบ้านช็อป',
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'คุณคือใคร?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: 150,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // ไปหน้าเลือกจังหวัดสำหรับผู้ซื้อ
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProvinceSelectionPage(),
                      ),
                    );
                    
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'ผู้ซื้อ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: 150,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // ไปหน้าเลือกจังหวัดสำหรับผู้ขาย
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SellerLoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 47, 219, 93),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'ผู้ขาย',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}