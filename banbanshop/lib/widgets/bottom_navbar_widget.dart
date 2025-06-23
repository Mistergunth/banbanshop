import 'package:flutter/material.dart';

class BottomNavbarWidget extends StatefulWidget {
  const BottomNavbarWidget({super.key});

  @override
  State<BottomNavbarWidget> createState() => _BottomNavbarWidgetState();
}

class _BottomNavbarWidgetState extends State<BottomNavbarWidget> {
  int _selectedIndex = 0; // สร้างตัวแปรสถานะเพื่อเก็บค่า index ของ destination ที่ถูกเลือก
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        backgroundColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF9C6ADE)),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF9C6ADE)),
            label: 'ตะกร้า',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF9C6ADE)), // เพิ่ม selectedIcon
            label: 'โปรไฟล์',
          ),
        ],
        selectedIndex: _selectedIndex, // ใช้ตัวแปรสถานะ
        onDestinationSelected: (int value) {
          setState(() {
            _selectedIndex = value; // อัปเดตค่า _selectedIndex เมื่อมีการเลือก
          });
          print('Selected index: $value');
        },
      );
  }
}