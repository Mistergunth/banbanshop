import 'package:flutter/material.dart'; 
import 'main_screen.dart';

class ProvinceSelection extends StatelessWidget {
  ProvinceSelection({super.key});

  final List<String> provinces = [
    'กรุงเทพมหานคร',
    'นนทบุรี',
    'ปทุมธานี',
    'สมุทรปราการ',
    'สมุทรสาคร',
    'นครปฐม',
    'พระนครศรีอยุธยา',
    'ลพบุรี',
    'สระบุรี',
    'อ่างทอง',
    'สิงห์บุรี',
    'ชัยนาท',
    'สุพรรณบุรี',
    'นครสวรรค์',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกจังหวัด'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกจังหวัดที่คุณต้องการ:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('เพื่อให้เราแสดงร้านค้าในพื้นที่ของคุณ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: provinces.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_on,
                      color: Colors.green
                      ),
                      title: Text(provinces[index]),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainScreen(
                              selectedProvince: provinces[index]),
                          ),
                        );
                      }
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )
    );
  }
}