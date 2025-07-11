import 'package:flutter/material.dart';

class BottomNavbarWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool isSeller;
  final bool hasStore;

  const BottomNavbarWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isSeller,
    required this.hasStore,
  });

  @override
  Widget build(BuildContext context) {
    // --- [KEY CHANGE] สร้างรายการของปุ่ม destinations แบบไดนามิก ---
    final List<Widget> destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: Color(0xFF9C6ADE)),
        label: 'หน้าแรก',
      ),
      // --- ใช้ isSeller เพื่อกำหนดไอคอนและข้อความ ---
      if (isSeller)
        const NavigationDestination(
          icon: Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF9C6ADE)),
          label: 'ออเดอร์',
        )
      else
        const NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF9C6ADE)),
          label: 'ตะกร้า',
        ),
      const NavigationDestination(
        icon: Icon(Icons.add_box_outlined),
        selectedIcon: Icon(Icons.add_box, color: Color(0xFF9C6ADE)),
        label: 'สร้างโพสต์',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person, color: Color(0xFF9C6ADE)),
        label: 'โปรไฟล์',
      ),
    ];

    return NavigationBar(
      backgroundColor: Colors.white,
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (int value) {
        onItemSelected(value);
      },
    );
  }
}
