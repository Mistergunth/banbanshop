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
  // final String openingHours; // [REMOVED] Replaced by a structured map
  final String phoneNumber;
  final DateTime createdAt;
  final String province;
  final double averageRating;
  final int reviewCount;

  // --- [NEW] Fields for Store Hours ---
  final bool isManuallyClosed; // สำหรับปุ่มเปิด-ปิดร้านแบบ Manual
  final Map<String, dynamic> operatingHours; // สำหรับเก็บตารางเวลา

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
    // required this.openingHours, // [REMOVED]
    required this.phoneNumber,
    required this.createdAt,
    required this.province,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    // --- [NEW] Initialize new fields ---
    this.isManuallyClosed = false,
    Map<String, dynamic>? operatingHours,
  }) : operatingHours = operatingHours ?? Store.defaultHours();


  // --- [NEW] Helper getter to determine if the store is currently open ---
  bool get isOpen {
    // 1. Check manual override first. If manually closed, it's always closed.
    if (isManuallyClosed) {
      return false;
    }

    // 2. Get current day and time in Thailand
    final now = DateTime.now().toUtc().add(const Duration(hours: 7)); // Convert to Thailand time (UTC+7)
    final String currentDay = DateFormat('E').format(now).toLowerCase().substring(0, 3); // e.g., 'mon', 'tue'
    final TimeOfDay currentTime = TimeOfDay.fromDateTime(now);

    // 3. Get today's schedule from the map
    final todaySchedule = operatingHours[currentDay];
    if (todaySchedule == null || todaySchedule['isOpen'] == false) {
      return false; // Not scheduled to be open today
    }

    // 4. Parse opening and closing times
    final TimeOfDay opensAt = _parseTime(todaySchedule['opens']);
    final TimeOfDay closesAt = _parseTime(todaySchedule['closes']);

    // 5. Compare current time with the schedule
    final double nowInMinutes = currentTime.hour * 60.0 + currentTime.minute;
    final double opensInMinutes = opensAt.hour * 60.0 + opensAt.minute;
    final double closesInMinutes = closesAt.hour * 60.0 + closesAt.minute;

    return nowInMinutes >= opensInMinutes && nowInMinutes < closesInMinutes;
  }

  // --- [NEW] Helper to parse time string "HH:mm" to TimeOfDay ---
  static TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      // Return a default time if parsing fails to prevent crashes
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  // --- [NEW] Default hours for a new store ---
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
      // openingHours: data['openingHours'] ?? '', // [REMOVED]
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      province: data['province'] ?? '',
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      // --- [NEW] Read new fields from Firestore ---
      isManuallyClosed: data['isManuallyClosed'] ?? false,
      operatingHours: data['operatingHours'] != null ? Map<String, dynamic>.from(data['operatingHours']) : Store.defaultHours(),
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
      // 'openingHours': openingHours, // [REMOVED]
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'province': province,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      // --- [NEW] Write new fields to Firestore ---
      'isManuallyClosed': isManuallyClosed,
      'operatingHours': operatingHours,
    };
  }
}
