// lib/screens/buyer/buyer_pickup_tracking_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerPickupTrackingScreen extends StatefulWidget {
  final Order order;

  const BuyerPickupTrackingScreen({super.key, required this.order});

  @override
  State<BuyerPickupTrackingScreen> createState() =>
      _BuyerPickupTrackingScreenState();
}

class _BuyerPickupTrackingScreenState extends State<BuyerPickupTrackingScreen> {
  final loc.Location _locationController = loc.Location();
  GoogleMapController? _mapController;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  Timer? _gpsCheckTimer;
  PolylinePoints polylinePoints = PolylinePoints();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _routeInfo = '';
  BuyerProfile? _buyerProfile;
  Store? _store;

  bool _isLoading = true;
  loc.LocationData? _previousLocation;
  double _markerRotation = 0.0;

  Timer? _debounce;
  bool _isCalculatingRoute = false;

  final String _googleApiKey = "AIzaSyCPW7zj9TLXyCtiZGMPOxIeWnIeAL7njKY";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _gpsCheckTimer?.cancel();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await _fetchUsersAndStore();
      await _addDestinationMarker();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      await _checkPermissionsAndStartTracking();

    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลด: $e')));
      }
    }
  }

  Future<void> _fetchUsersAndStore() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'ไม่พบข้อมูลผู้ใช้';

      final buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(currentUser.uid)
          .get();
      if (buyerDoc.exists) {
        _buyerProfile = BuyerProfile.fromFirestore(buyerDoc);
      }

      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.order.storeId)
          .get();
      if (storeDoc.exists) {
        _store = Store.fromFirestore(storeDoc);
      }

    } catch (e) {
      print("Error fetching user/store data: $e");
      rethrow;
    }
  }

  Future<void> _addDestinationMarker() async {
    if (!mounted || _store?.latitude == null || _store?.longitude == null) return;

    final destinationIcon = await _createCustomMarkerBitmap(
        _store?.imageUrl, Colors.greenAccent, isDestination: true);
        
    if (mounted) {
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_store!.latitude!, _store!.longitude!),
          icon: destinationIcon,
          infoWindow: InfoWindow(title: 'ร้านค้า: ${_store?.name}'),
          anchor: const Offset(0.5, 0.5),
        ));
      });
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) return;

    loc.PermissionStatus permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }
    
    _startLiveTracking();
  }

  void _startLiveTracking() {
    _locationController.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 2000, 
      distanceFilter: 0,
    );

    _gpsCheckTimer?.cancel();
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      bool serviceEnabled = await _locationController.serviceEnabled();
      if (!serviceEnabled) {
        timer.cancel();
        _locationSubscription?.cancel();
      }
    });

    _locationSubscription = _locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        _updateMapAndFirestore(currentLocation);
      }
    });
  }

  Future<void> _updateMapAndFirestore(loc.LocationData currentLocation) async {
    if (!mounted || _buyerProfile == null) return;

    final newPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);

    if (_previousLocation == null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));
    }

    double distanceMoved = 0;
    if (_previousLocation != null) {
      distanceMoved = Geolocator.distanceBetween(
        _previousLocation!.latitude!, _previousLocation!.longitude!,
        currentLocation.latitude!, currentLocation.longitude!,
      );
    }
    
    if (distanceMoved > 3) {
      _markerRotation = _calculateBearing(_previousLocation!, currentLocation);
    }
    
    _previousLocation = currentLocation;

    final buyerIcon = await _createNavigationArrowMarker();

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: newPosition,
        icon: buyerIcon,
        rotation: _markerRotation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      ));
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 8), () {
       if (_store?.latitude != null && _store?.longitude != null) {
        final destinationPosition = LatLng(_store!.latitude!, _store!.longitude!);
        _drawRoute(newPosition, destinationPosition);
      }
    });
    
    FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.order.storeId)
        .collection('orders')
        .doc(widget.order.id)
        .update({
      'buyerLocation': GeoPoint(currentLocation.latitude!, currentLocation.longitude!),
      'lastLocationUpdate': Timestamp.now(),
    });
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
     if (_isCalculatingRoute) return;
    
    setState(() => _isCalculatingRoute = true);

    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'OK' && jsonResponse['routes'].isNotEmpty) {
          final route = jsonResponse['routes'][0];
          final leg = route['legs'][0];
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          
          final overviewPolyline = route['overview_polyline']['points'];
          final List<PointLatLng> points = polylinePoints.decodePolyline(overviewPolyline);
          
          if (points.isNotEmpty) {
            List<LatLng> polylineCoordinates = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
            if (mounted) {
              setState(() {
                 _polylines.clear();
                 _polylines.add(Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.teal,
                  width: 5,
                  points: polylineCoordinates,
                ));
                _routeInfo = '$distance - ประมาณ $duration';
              });
            }
          }
        } else {
           if (mounted) setState(() => _routeInfo = 'ไม่สามารถคำนวณเส้นทางได้');
        }
      } else {
         if (mounted) setState(() => _routeInfo = 'ไม่สามารถเชื่อมต่อ API ได้');
      }
    } catch (e) {
      if (mounted) setState(() => _routeInfo = 'เกิดข้อผิดพลาดในการคำนวณเส้นทาง');
    } finally {
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  Future<void> _confirmAndStopSharing() async {
    _locationSubscription?.cancel();
    _gpsCheckTimer?.cancel();
    _debounce?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('หยุดการแชร์ตำแหน่งแล้ว'), backgroundColor: Colors.orange),
    );
    Navigator.of(context).pop();
  }
  
  CameraPosition _getInitialCameraPosition() {
    if (_store?.latitude != null && _store?.longitude != null) {
      return CameraPosition(
        target: LatLng(_store!.latitude!, _store!.longitude!),
        zoom: 14.0,
      );
    }
    return const CameraPosition(target: LatLng(13.7563, 100.5018), zoom: 12);
  }

  double _calculateBearing(loc.LocationData start, loc.LocationData end) {
    final double startLat = start.latitude! * math.pi / 180;
    final double startLng = start.longitude! * math.pi / 180;
    final double endLat = end.latitude! * math.pi / 180;
    final double endLng = end.longitude! * math.pi / 180;
    final double dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) - math.sin(startLat) * math.cos(endLat) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  Future<BitmapDescriptor> _createNavigationArrowMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.teal;
    const double width = 60.0;
    const double height = 80.0;
    final Path path = Path();
    path.moveTo(width / 2, 0);
    path.lineTo(width, height);
    path.lineTo(width / 2, height * 0.75);
    path.lineTo(0, height);
    path.close();
    canvas.drawPath(path, paint);
    final img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String? imageUrl, Color borderColor, {bool isDestination = false}) async {
    try {
      const int size = 150;
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..color = Colors.white;
      final Paint borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;

      canvas.drawCircle(
          const Offset(size / 2, size / 2), size / 2, borderPaint);
      canvas.drawCircle(
          const Offset(size / 2, size / 2), size / 2 - 5, paint);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        final Uint8List imageBytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(imageBytes,
            targetWidth: size - 30, targetHeight: size - 30);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();

        final Path clipPath = Path()
          ..addOval(Rect.fromLTWH(
              15, 15, (size - 30).toDouble(), (size - 30).toDouble()));
        canvas.clipPath(clipPath);

        canvas.drawImage(frameInfo.image, const Offset(15, 15), Paint());
      } else {
        final icon = isDestination ? Icons.store : Icons.person;
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: icon.fontFamily, textAlign: TextAlign.center))
          ..pushStyle(ui.TextStyle(color: Colors.grey[600], fontSize: 80.0))
          ..addText(String.fromCharCode(icon.codePoint));
        final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: size.toDouble()));
        canvas.drawParagraph(paragraph, Offset(0, (size - paragraph.height) / 2));
      }

      final img = await pictureRecorder.endRecording().toImage(size, size);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    } catch (e) {
      print("Error creating custom marker: $e");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // --- [NEW] Function to recenter map on the buyer's location ---
  void _recenterMap() {
    if (_previousLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_previousLocation!.latitude!, _previousLocation!.longitude!),
          17.0,
        ),
      );
    }
  }

  // --- [NEW] Function to force redraw the route ---
  void _forceRedrawRoute() {
    if (_previousLocation != null && _store?.latitude != null && _store?.longitude != null) {
      _debounce?.cancel();
      final origin = LatLng(_previousLocation!.latitude!, _previousLocation!.longitude!);
      final destination = LatLng(_store!.latitude!, _store!.longitude!);
      _drawRoute(origin, destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เดินทางไปรับสินค้า'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) => _mapController = controller,
                  initialCameraPosition: _getInitialCameraPosition(),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                ),
                // --- [NEW] Add map control buttons ---
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'recenter_button_buyer',
                        onPressed: _recenterMap,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.gps_fixed, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: 'route_button_buyer',
                        onPressed: _forceRedrawRoute,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.route, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: (_store?.imageUrl != null) ? NetworkImage(_store!.imageUrl!) : null,
                            child: (_store?.imageUrl == null) ? const Icon(Icons.store) : null,
                          ),
                          title: Text(_store?.name ?? 'ร้านค้า', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          subtitle: Text(_routeInfo.isEmpty ? 'กำลังคำนวณเส้นทาง...' : _routeInfo, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 10),
                         SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('หยุดแชร์ตำแหน่ง'),
                            onPressed: _confirmAndStopSharing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
