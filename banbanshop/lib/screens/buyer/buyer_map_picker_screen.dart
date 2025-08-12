// lib/screens/buyer/buyer_map_picker_screen.dart

// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

class BuyerMapPickerScreen extends StatefulWidget {
  final LatLng? initialLatLng;

  const BuyerMapPickerScreen({super.key, this.initialLatLng});

  @override
  State<BuyerMapPickerScreen> createState() => _BuyerMapPickerScreenState();
}

class _BuyerMapPickerScreenState extends State<BuyerMapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = 'กำลังค้นหาที่อยู่...';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController(); // Added search controller

  static const LatLng _initialPosition = LatLng(13.7563, 100.5018); // ตำแหน่งเริ่มต้นที่กรุงเทพ

  @override
  void initState() {
    super.initState();
    if (widget.initialLatLng != null) {
      _selectedLocation = widget.initialLatLng;
      _getAddressFromLatLng(widget.initialLatLng!);
      _isLoading = false;
    } else {
      _getUserLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose search controller
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        _setDefaultLocation();
        return;
      }
    }

    try {
      final loc.LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final userLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        setState(() {
          _selectedLocation = userLatLng;
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));
        _getAddressFromLatLng(userLatLng);
      } else {
        _setDefaultLocation();
      }
    } catch (e) {
      print("Error getting user location: $e");
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _selectedLocation = _initialPosition;
      _isLoading = false;
    });
    _getAddressFromLatLng(_initialPosition);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        setState(() {
          _selectedAddress =
              '${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.postalCode}';
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _selectedAddress = "ไม่สามารถค้นหาที่อยู่ได้";
      });
    }
  }

  // New: Function to search for a location by address
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final firstLocation = locations.first;
        final newLatLng = LatLng(firstLocation.latitude, firstLocation.longitude);
        setState(() {
          _selectedLocation = newLatLng;
          _isLoading = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
        _getAddressFromLatLng(newLatLng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบที่อยู่ดังกล่าว')),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error searching location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการค้นหา: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    _getAddressFromLatLng(position);
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งบนแผนที่')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ปักหมุดที่อยู่จัดส่ง'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Blue to Dark Purple gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white, // White text/icons
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
            tooltip: 'ตำแหน่งปัจจุบัน',
            color: Colors.white, // White icon
          )
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1))) // Blue loading
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _initialPosition,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTapped,
                  markers: _selectedLocation == null
                      ? {}
                      : {
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: _selectedLocation!,
                            infoWindow: InfoWindow(title: 'ตำแหน่งที่เลือก', snippet: _selectedAddress),
                            draggable: true,
                            onDragEnd: (newPosition) {
                              _onMapTapped(newPosition);
                            },
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Orange marker
                          ),
                        },
                ),
          // Search bar
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
                  hintStyle: TextStyle(color: Colors.grey[600]), // Darker hint text
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF0288D1)), // Blue search icon
                    onPressed: () => _searchLocation(_searchController.text),
                  ),
                ),
                onSubmitted: _searchLocation, // Search on submit
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
                  const Text('ตำแหน่งที่เลือก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), // Darker text
                  const SizedBox(height: 8),
                  Text(_selectedAddress, style: const TextStyle(fontSize: 16, color: Colors.grey)), // Grey text
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0288D1), // Blue button
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
