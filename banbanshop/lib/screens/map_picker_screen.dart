// lib/screens/map_picker_screen.dart

// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // แก้ไข import ตรงนี้
import 'package:geolocator/geolocator.dart'; // สำหรับตำแหน่งปัจจุบัน
import 'package:geocoding/geocoding.dart'; // สำหรับ reverse geocoding

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isLoadingLocation = true;
  String _currentAddress = 'กำลังโหลดตำแหน่ง...';

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
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
        _pickedLocation = const LatLng(13.7563, 100.5018); // Default to Bangkok
        _currentAddress = 'กรุงเทพมหานคร';
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
          _currentAddress = 'กรุงเทพมหานคร';
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
        _currentAddress = 'กรุงเทพมหานคร';
      });
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _updateAddress(_pickedLocation!);
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

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
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
                      _updateAddress(_pickedLocation!); // อัปเดตที่อยู่เริ่มต้น
                    },
                    onTap: (LatLng latLng) {
                      setState(() {
                        _pickedLocation = latLng;
                        _updateAddress(latLng);
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
