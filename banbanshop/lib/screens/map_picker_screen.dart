// lib/screens/map_picker_screen.dart

// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // สำหรับตำแหน่งปัจจุบัน
import 'package:geocoding/geocoding.dart'; // สำหรับ reverse geocoding

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // ignore: unused_field
  GoogleMapController? _mapController;
  LatLng? _pickedLocation; // ตำแหน่งที่ผู้ใช้เลือก
  bool _isLoadingLocation = true; // สถานะการโหลดตำแหน่งเริ่มต้น
  String _currentAddress = 'กำลังโหลดตำแหน่ง...'; // ที่อยู่ปัจจุบันที่แสดง

  @override
  void initState() {
    super.initState();
    _determinePosition(); // เริ่มต้นด้วยการดึงตำแหน่งปัจจุบันของผู้ใช้
  }

  // ตรวจสอบสิทธิ์และดึงตำแหน่งปัจจุบัน
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าบริการตำแหน่งเปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        // ตั้งค่าเริ่มต้นเป็นกรุงเทพฯ หากไม่สามารถเข้าถึงตำแหน่งได้
        _pickedLocation = const LatLng(13.7563, 100.5018); // Default to Bangkok, Thailand
        _currentAddress = 'กรุงเทพมหานคร (ค่าเริ่มต้น)';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        setState(() {
          _isLoadingLocation = false;
          _pickedLocation = const LatLng(13.7563, 100.5018); // Default to Bangkok
          _currentAddress = 'กรุงเทพมหานคร (ค่าเริ่มต้น)';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        _pickedLocation = const LatLng(13.7563, 100.5018); // Default to Bangkok
        _currentAddress = 'กรุงเทพมหานคร (ค่าเริ่มต้น)';
      });
      return;
    }

    // หากได้รับสิทธิ์แล้ว ให้ดึงตำแหน่งปัจจุบัน
    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _updateAddress(_pickedLocation!); // อัปเดตที่อยู่ตามตำแหน่งที่ได้
      });
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึงตำแหน่งปัจจุบันได้: $e')),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        _pickedLocation = const LatLng(13.7563, 100.5018); // Default to Bangkok
        _currentAddress = 'กรุงเทพมหานคร (ค่าเริ่มต้น)';
      });
    }
  }

  // แปลง LatLng เป็นที่อยู่ (Reverse Geocoding)
  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          // สร้างที่อยู่จากข้อมูล Placemark
          _currentAddress =
              '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea} ${p.postalCode}';
        });
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      setState(() {
        _currentAddress = 'ไม่สามารถระบุที่อยู่ได้';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปักหมุดตำแหน่งร้าน', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFE8F4FD),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingLocation || _pickedLocation == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9C6ADE)))
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _pickedLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      _updateAddress(_pickedLocation!); // อัปเดตที่อยู่เริ่มต้นเมื่อแผนที่สร้างเสร็จ
                    },
                    onTap: (LatLng latLng) {
                      setState(() {
                        _pickedLocation = latLng; // อัปเดตตำแหน่งที่ผู้ใช้แตะ
                        _updateAddress(latLng); // อัปเดตที่อยู่ตามตำแหน่งใหม่
                      });
                    },
                    markers: _pickedLocation == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('pickedLocation'),
                              position: _pickedLocation!,
                              infoWindow: InfoWindow(title: 'ตำแหน่งร้าน', snippet: _currentAddress),
                            ),
                          },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ตำแหน่งที่เลือก:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentAddress,
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_pickedLocation != null) {
                            Navigator.pop(context, {
                              'latitude': _pickedLocation!.latitude,
                              'longitude': _pickedLocation!.longitude,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่ก่อน')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C6ADE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'ยืนยันตำแหน่งนี้',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
