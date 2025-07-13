// lib/screens/models/address_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String id;
  final String label; // เช่น บ้าน, ที่ทำงาน
  final String contactName;
  final String phoneNumber;
  final String addressLine;
  final GeoPoint location; // สำหรับเก็บพิกัด Lat, Lng
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.contactName,
    required this.phoneNumber,
    required this.addressLine,
    required this.location,
    this.isDefault = false,
  });

  factory Address.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Address(
      id: doc.id,
      label: data['label'] ?? '',
      contactName: data['contactName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      addressLine: data['addressLine'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'addressLine': addressLine,
      'location': location,
      'isDefault': isDefault,
    };
  }
}
