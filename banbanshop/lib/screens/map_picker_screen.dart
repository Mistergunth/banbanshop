// lib/screens/map_picker_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLatLng;
  const MapPickerScreen({super.key, this.initialLatLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _isLoading = true;
  String _currentAddress = 'กำลังโหลดตำแหน่ง...';
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _initialPosition = LatLng(13.7563, 100.5018); // Bangkok

  @override
  void initState() {
    super.initState();
    if (widget.initialLatLng != null) {
      _pickedLocation = widget.initialLatLng;
      _getAddressFromLatLng(_pickedLocation!);
      _isLoading = false;
    } else {
      _getUserLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true;
      _currentAddress = 'กำลังโหลดตำแหน่ง...';
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setDefaultLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิดบริการระบุตำแหน่ง (GPS)')),
      );
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คุณปฏิเสธการเข้าถึงตำแหน่ง')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเปิดการเข้าถึงตำแหน่งในการตั้งค่าแอป')),
      );
      await Geolocator.openAppSettings();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _pickedLocation = userLatLng;
        _isLoading = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));
      _getAddressFromLatLng(userLatLng);
    } catch (e) {
      print('Error getting current location: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _pickedLocation = _initialPosition;
      _isLoading = false;
    });
    _getAddressFromLatLng(_initialPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress = '${p.street}, ${p.subLocality}, ${p.locality}, ${p.administrativeArea} ${p.postalCode}';
        });
      } else {
        setState(() => _currentAddress = 'ไม่พบที่อยู่สำหรับพิกัดนี้');
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      setState(() => _currentAddress = 'ไม่สามารถระบุที่อยู่ได้');
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        final newLatLng = LatLng(firstLocation.latitude, firstLocation.longitude);
        setState(() {
          _pickedLocation = newLatLng;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
        _getAddressFromLatLng(newLatLng);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบที่อยู่ดังกล่าว')),
        );
      }
    } catch (e) {
      print("Error searching location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
    _getAddressFromLatLng(position);
  }

  void _confirmSelection() {
    if (_pickedLocation != null) {
      Navigator.pop(context, {
        'latitude': _pickedLocation!.latitude,
        'longitude': _pickedLocation!.longitude,
        'address': _currentAddress,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่ก่อน')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปักหมุดตำแหน่งร้าน'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
            tooltip: 'ตำแหน่งปัจจุบัน',
            color: Colors.white,
          )
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLocation ?? _initialPosition,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTapped,
                  markers: _pickedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('pickedLocation'),
                            position: _pickedLocation!,
                            infoWindow: InfoWindow(title: 'ตำแหน่งร้าน', snippet: _currentAddress),
                            draggable: true,
                            onDragEnd: (newPosition) {
                              _onMapTapped(newPosition);
                            },
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
                          ),
                        },
                ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาที่อยู่...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF0288D1)),
                    onPressed: () => _searchLocation(_searchController.text),
                  ),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ตำแหน่งที่เลือก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(_currentAddress, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ยืนยันตำแหน่งนี้', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
