// lib/screens/models/seller_profile.dart

// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';


class SellerProfile {
  String fullName;
  String phoneNumber;
  String idCardNumber;
  String province;
  String password;
  String email;
  String? profileImageUrl;
  bool? hasStore; 
  String? storeId; 
  String? shopName; 
  String? shopAvatarImageUrl; 
  String? shopPhoneNumber; 
  double? shopLatitude; 
  double? shopLongitude; 

  SellerProfile({
    required this.fullName,
    required this.phoneNumber,
    required this.idCardNumber,
    required this.province,
    required this.password,
    required this.email,
    this.profileImageUrl,
    this.shopAvatarImageUrl, 
    this.hasStore,
    this.storeId,
    this.shopName,
    this.shopPhoneNumber, 
    this.shopLatitude, 
    this.shopLongitude, 
  });


  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      idCardNumber: json['idCardNumber'] as String? ?? '',
      province: json['province'] as String? ?? '',
      password: json['password'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      shopAvatarImageUrl: json['shopAvatarImageUrl'] as String?, 
      hasStore: json['hasStore'] as bool?, 
      storeId: json['storeId'] as String?, 
      shopName: json['shopName'] as String?, 
      shopPhoneNumber: json['shopPhoneNumber'] as String?, 
      shopLatitude: (json['shopLatitude'] as num?)?.toDouble(), 
      shopLongitude: (json['shopLongitude'] as num?)?.toDouble(), 
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'idCardNumber': idCardNumber,
      'province': province,
      'password': password,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'hasStore': hasStore, 
      'storeId': storeId, 
      'shopName': shopName, 
      'shopAvatarImageUrl': shopAvatarImageUrl, 
      'shopPhoneNumber': shopPhoneNumber, 
      'shopLatitude': shopLatitude, 
      'shopLongitude': shopLongitude, 
    };
  }

  SellerProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? idCardNumber,
    String? province,
    String? password,
    String? email,
    String? profileImageUrl,
    bool? hasStore,
    String? storeId,
    String? shopName,
    String? shopAvatarImageUrl, 
    String? shopPhoneNumber,
    double? shopLatitude,
    double? shopLongitude,
  }) {
    return SellerProfile(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      province: province ?? this.province,
      password: password ?? this.password,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasStore: hasStore ?? this.hasStore,
      storeId: storeId ?? this.storeId,
      shopName: shopName ?? this.shopName,
      shopAvatarImageUrl: shopAvatarImageUrl ?? this.shopAvatarImageUrl, 
      shopPhoneNumber: shopPhoneNumber ?? this.shopPhoneNumber,
      shopLatitude: shopLatitude ?? this.shopLatitude,
      shopLongitude: shopLongitude ?? this.shopLongitude,
    );
  }
}
