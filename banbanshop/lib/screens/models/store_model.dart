// lib/screens/models/store_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Store {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String type;
  final String? category;
  final String? imageUrl;
  final String locationAddress;
  final double? latitude;
  final double? longitude;
  final String phoneNumber;
  final DateTime createdAt;
  final String province;
  final double averageRating;
  final int reviewCount;
  final bool isManuallyClosed; 
  final Map<String, dynamic> operatingHours;

  // --- [NEW] เพิ่มฟิลด์สำหรับข้อมูลการชำระเงิน ---
  final Map<String, dynamic>? paymentInfo;

  Store({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    required this.type,
    this.category,
    this.imageUrl,
    required this.locationAddress,
    this.latitude,
    this.longitude,
    required this.phoneNumber,
    required this.createdAt,
    required this.province,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isManuallyClosed = false,
    Map<String, dynamic>? operatingHours,
    // --- [NEW] เพิ่ม paymentInfo ใน constructor ---
    this.paymentInfo,
  }) : operatingHours = operatingHours ?? Store.defaultHours();


  bool get isOpen {
    if (isManuallyClosed) {
      return false;
    }
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final String currentDay = DateFormat('E').format(now).toLowerCase().substring(0, 3);
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(now);
    final todaySchedule = operatingHours[currentDay];
    if (todaySchedule == null || todaySchedule['isOpen'] == false) {
      return false;
    }
    final TimeOfDay opensAt = _parseTime(todaySchedule['opens']);
    final TimeOfDay closesAt = _parseTime(todaySchedule['closes']);
    final double nowInMinutes = currentTime.hour * 60.0 + currentTime.minute;
    final double opensInMinutes = opensAt.hour * 60.0 + opensAt.minute;
    final double closesInMinutes = closesAt.hour * 60.0 + closesAt.minute;
    return nowInMinutes >= opensInMinutes && nowInMinutes < closesInMinutes;
  }

  static TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  static Map<String, dynamic> defaultHours() {
    return {
      'mon': {'isOpen': true, 'opens': '09:00', 'closes': '18:00'},
      'tue': {'isOpen': true, 'opens': '09:00', 'closes': '18:00'},
      'wed': {'isOpen': true, 'opens': '09:00', 'closes': '18:00'},
      'thu': {'isOpen': true, 'opens': '09:00', 'closes': '18:00'},
      'fri': {'isOpen': true, 'opens': '09:00', 'closes': '18:00'},
      'sat': {'isOpen': false, 'opens': '09:00', 'closes': '18:00'},
      'sun': {'isOpen': false, 'opens': '09:00', 'closes': '18:00'},
    };
  }


  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      category: data['category'] as String?,
      imageUrl: data['imageUrl'],
      locationAddress: data['locationAddress'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      province: data['province'] ?? '',
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      isManuallyClosed: data['isManuallyClosed'] ?? false,
      operatingHours: data['operatingHours'] != null ? Map<String, dynamic>.from(data['operatingHours']) : Store.defaultHours(),
      // --- [NEW] อ่านข้อมูล paymentInfo จาก Firestore ---
      paymentInfo: data['paymentInfo'] != null ? Map<String, dynamic>.from(data['paymentInfo']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'type': type,
      'category': category,
      'imageUrl': imageUrl,
      'locationAddress': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'province': province,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'isManuallyClosed': isManuallyClosed,
      'operatingHours': operatingHours,
      // --- [NEW] เขียนข้อมูล paymentInfo ลง Firestore ---
      'paymentInfo': paymentInfo,
    };
  }
}
