import 'package:flutter/material.dart';


class MainScreen extends StatefulWidget {
  final String selectedProvince;

  const MainScreen({super.key, required this.selectedProvince});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('บ้านบ้านช็อป - ${widget.selectedProvince}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'ยินดีต้อนรับสู่บ้านบ้านช็อป\nจังหวัด: ${widget.selectedProvince}',
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}