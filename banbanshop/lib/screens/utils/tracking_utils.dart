// lib/utils/tracking_utils.dart

import 'package:uuid/uuid.dart'; // เพิ่ม package uuid ใน pubspec.yaml

class TrackingUtils {
  static const Uuid _uuid = Uuid();

  // ฟังก์ชันสำหรับสร้าง Tracking ID ที่ไม่ซ้ำกัน (UUID v4)
  static String generateTrackingId() {
    return _uuid.v4();
  }

  // ฟังก์ชันสำหรับสร้าง Tracking Link
  // baseURL ควรเป็น URL ของเว็บแอปติดตามของคุณ (เช่น 'https://your-domain.web.app/track')
  // orderId และ trackingId จะถูกเพิ่มเป็น Query Parameters
  static String generateTrackingLink(String baseURL, String orderId, String trackingId) {
    return '$baseURL?orderId=$orderId&trackingId=$trackingId';
  }
}