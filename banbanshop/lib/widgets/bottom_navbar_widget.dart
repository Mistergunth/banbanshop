import 'package:flutter/material.dart';

// เปลี่ยน BottomNavbarWidget ให้เป็น StatelessWidget
// เพื่อให้ Widget ภายนอก (Parent) เป็นผู้ควบคุม selectedIndex และการเปลี่ยนหน้า
class BottomNavbarWidget extends StatelessWidget {
  // selectedIndex คือ Index ของแท็บที่ถูกเลือกในปัจจุบัน
  final int selectedIndex; 
  // onItemSelected คือ Callback ที่จะถูกเรียกเมื่อผู้ใช้เลือกแท็บ
  final ValueChanged<int> onItemSelected; 

  const BottomNavbarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected, required bool isSeller, required bool hasStore,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
        backgroundColor: Colors.white,
        // กำหนด Destination (แท็บ) สำหรับ Navigation Bar
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined), // Icon เมื่อไม่ได้เลือก
            selectedIcon: Icon(Icons.home, color: Color(0xFF9C6ADE)), // Icon เมื่อเลือก
            label: 'หน้าแรก', // ข้อความกำกับแท็บ
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF9C6ADE)),
            label: 'ออเดอร์', // สำหรับผู้ขาย, แท็บนี้อาจหมายถึง "ออเดอร์"
          ),
          // เพิ่มปุ่ม "สร้างโพสต์" ที่นี่
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined), // ไอคอนสำหรับสร้างโพสต์
            selectedIcon: Icon(Icons.add_box, color: Color(0xFF9C6ADE)), // ไอคอนเมื่อเลือก
            label: 'สร้างโพสต์', // ข้อความกำกับแท็บ
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person, color: Color(0xFF9C6ADE)),
            label: 'โปรไฟล์',
          ),
        ],
        // selectedIndex ที่ถูกส่งมาจาก Parent Widget
        selectedIndex: selectedIndex, 
        // Callback ที่จะส่งค่า index ของแท็บที่เลือกกลับไปให้ Parent Widget
        onDestinationSelected: (int value) {
          onItemSelected(value); 
        },
      );
  }
}
