import 'package:flutter/material.dart';
import 'screens/province_selection.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BanBanShopApp());
}

class BanBanShopApp extends StatelessWidget {
  const BanBanShopApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'บ้านบ้านช็อป',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Kanit',
      ),
      home: ProvinceSelection(),
    );
  }
}
