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
    // สร้างรายการของปุ่ม destinations แบบไดนามิก
    final List<Widget> destinations = [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home, color: Color(0xFF6A1B9A)), // Selected icon color: Orange/Yellow from icon
        label: 'หน้าแรก',
      ),
      // ใช้ isSeller เพื่อกำหนดไอคอนและข้อความ
      if (isSeller)
        NavigationDestination(
          icon: const Icon(Icons.shopping_bag_outlined),
          selectedIcon: Icon(Icons.shopping_bag, color: Color(0xFF6A1B9A)), // Selected icon color: Orange/Yellow from icon
          label: 'ออเดอร์',
        )
      else
        NavigationDestination(
          icon: const Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF6A1B9A)), // Selected icon color: Orange/Yellow from icon
          label: 'ตะกร้า',
        ),
      NavigationDestination(
        icon: const Icon(Icons.add_box_outlined),
        selectedIcon: Icon(Icons.add_box, color: Color(0xFF6A1B9A)), // Selected icon color: Orange/Yellow from icon
        label: 'สร้างโพสต์',
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outlined),
        selectedIcon: Icon(Icons.person, color: Color(0xFF6A1B9A)), // Selected icon color: Orange/Yellow from icon
        label: 'โปรไฟล์',
      ),
    ];

    return NavigationBar(
      backgroundColor: const Color(0xFFF8FCFE), // Very light blue background to match the icon theme
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: (int value) {
        onItemSelected(value);
      },
      indicatorColor: Colors.blue.shade100, // Light blue indicator color to highlight selected item
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow, // Always show labels
      elevation: 5, // Add some elevation for a subtle lift effect
    );
  }
}
