import 'package:flutter/material.dart'; 

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: provinces.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(provinces[index]),
                    onTap: () {
                      // Handle province selection
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('คุณเลือก ${provinces[index]}')),
                      );
                    },
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