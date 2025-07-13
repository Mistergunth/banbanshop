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
        backgroundColor: const Color(0xFF9C6ADE),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
            tooltip: 'ตำแหน่งปัจจุบัน',
          )
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                          ),
                        },
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
                  const Text('ตำแหน่งที่เลือก', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_selectedAddress, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C6ADE),
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
