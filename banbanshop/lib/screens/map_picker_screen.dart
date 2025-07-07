// lib/screens/map_picker_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // สำหรับตำแหน่งปัจจุบัน
import 'package:geocoding/geocoding.dart'; // สำหรับ reverse geocoding

class MapPickerScreen extends StatefulWidget {
  // เพิ่ม initialLatLng parameter เพื่อให้สามารถกำหนดตำแหน่งเริ่มต้นได้
  final LatLng? initialLatLng;
  const MapPickerScreen({super.key, this.initialLatLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController; // ประกาศตัวแปร _mapController
  LatLng? _pickedLocation; // ตำแหน่งที่ผู้ใช้เลือก
  bool _isLoadingLocation = true; // สถานะการโหลดตำแหน่งเริ่มต้น
  String _currentAddress = 'กำลังโหลดตำแหน่ง...'; // ที่อยู่ปัจจุบันที่แสดง

  // ตำแหน่งเริ่มต้นเมื่อไม่สามารถดึงตำแหน่งปัจจุบันได้ (กรุงเทพมหานคร)
  static const LatLng _defaultLocation = LatLng(13.7563, 100.5018);
  static const String _defaultAddress = 'กรุงเทพมหานคร (ค่าเริ่มต้น)';

  @override
  void initState() {
    super.initState();
    // ถ้ามี initialLatLng มาให้ใช้ค่านั้นเป็นตำแหน่งเริ่มต้น
    if (widget.initialLatLng != null) {
      _pickedLocation = widget.initialLatLng;
      _updateAddress(_pickedLocation!);
      _isLoadingLocation = false;
    } else {
      _determinePosition(); // เริ่มต้นด้วยการดึงตำแหน่งปัจจุบันของผู้ใช้
    }
  }

  // ฟังก์ชันแสดง Dialog เมื่อบริการระบุตำแหน่งถูกปิด
  Future<void> _showLocationServiceDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // ผู้ใช้ต้องกดปุ่มใน dialog เท่านั้น
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('บริการระบุตำแหน่งถูกปิดอยู่'),
          content: const Text('กรุณาเปิดบริการระบุตำแหน่งในตั้งค่าอุปกรณ์ของคุณเพื่อใช้งานแผนที่'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isLoadingLocation = false;
                  _pickedLocation = _defaultLocation; // Default to Bangkok
                  _currentAddress = _defaultAddress;
                });
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings(); // เปิดหน้าตั้งค่าตำแหน่ง
                // หลังจากกลับจากตั้งค่า ลองดึงตำแหน่งอีกครั้ง
                _determinePosition();
              },
              child: const Text('เปิดการตั้งค่า'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันแสดง Dialog เมื่อสิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธ
  Future<void> _showPermissionDeniedDialog(bool permanentlyDenied) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(permanentlyDenied ? 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธถาวร' : 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธ'),
          content: Text(permanentlyDenied
              ? 'สิทธิ์การเข้าถึงตำแหน่งถูกปฏิเสธอย่างถาวร กรุณาไปที่การตั้งค่าแอปเพื่อเปิดใช้งานด้วยตนเอง'
              : 'คุณปฏิเสธการให้สิทธิ์เข้าถึงตำแหน่ง กรุณาให้สิทธิ์เพื่อใช้งานแผนที่'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _isLoadingLocation = false;
                  _pickedLocation = _defaultLocation; // Default to Bangkok
                  _currentAddress = _defaultAddress;
                });
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                if (permanentlyDenied) {
                  await Geolocator.openAppSettings(); // เปิดหน้าตั้งค่าแอป
                } else {
                  // Request permission again if not permanently denied
                  await Geolocator.requestPermission();
                }
                _determinePosition(); // ลองดึงตำแหน่งอีกครั้ง
              },
              child: Text(permanentlyDenied ? 'เปิดการตั้งค่าแอป' : 'ให้สิทธิ์'),
            ),
          ],
        );
      },
    );
  }

  // ตรวจสอบสิทธิ์และดึงตำแหน่งปัจจุบัน
  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _currentAddress = 'กำลังโหลดตำแหน่ง...';
    });

    bool serviceEnabled;
    LocationPermission permission;

    // 1. ตรวจสอบว่าบริการตำแหน่งเปิดอยู่หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        await _showLocationServiceDialog();
      }
      return; // ออกจากฟังก์ชันหลังจากแสดง dialog
    }

    // 2. ตรวจสอบและขอสิทธิ์การเข้าถึงตำแหน่ง
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          await _showPermissionDeniedDialog(false); // Not permanently denied
        }
        return; // ออกจากฟังก์ชันหลังจากแสดง dialog
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await _showPermissionDeniedDialog(true); // Permanently denied
      }
      return; // ออกจากฟังก์ชันหลังจากแสดง dialog
    }

    // หากได้รับสิทธิ์แล้ว ให้ดึงตำแหน่งปัจจุบัน
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _updateAddress(_pickedLocation!); // อัปเดตที่อยู่ตามตำแหน่งที่ได้
      });
      // ย้ายกล้องไปยังตำแหน่งปัจจุบัน
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_pickedLocation!),
      );
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถดึงตำแหน่งปัจจุบันได้: $e')),
        );
      }
      setState(() {
        _isLoadingLocation = false;
        _pickedLocation = _defaultLocation; // Default to Bangkok
        _currentAddress = _defaultAddress;
      });
      // ย้ายกล้องไปยังตำแหน่งเริ่มต้น (กรุงเทพฯ)
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_pickedLocation!),
      );
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
          // หากข้อมูลบางส่วนเป็น null หรือว่าง ให้กรองออก
          List<String?> addressParts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode
          ].where((part) => part != null && part.isNotEmpty).toList();
          _currentAddress = addressParts.join(', ');
        });
      } else {
        setState(() {
          _currentAddress = 'ไม่พบที่อยู่สำหรับพิกัดนี้';
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
                      _mapController = controller; // กำหนดค่าให้ _mapController ที่นี่
                      // ใช้ _mapController เพื่อเลื่อนกล้องไปยังตำแหน่งที่เลือก
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(_pickedLocation!),
                      );
                    },
                    onTap: (LatLng latLng) {
                      setState(() {
                        _pickedLocation = latLng; // อัปเดตตำแหน่งที่ผู้ใช้แตะ
                        _updateAddress(latLng); // อัปเดตที่อยู่ตามตำแหน่งใหม่
                        // ใช้ _mapController เพื่อเลื่อนกล้องไปยังตำแหน่งที่ผู้ใช้แตะ
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(latLng),
                        );
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
                            // คืนค่าเป็น Map<String, double> และ String address
                            Navigator.pop(context, {
                              'latitude': _pickedLocation!.latitude,
                              'longitude': _pickedLocation!.longitude,
                              'address': _currentAddress, // เพิ่ม address กลับไปด้วย
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
