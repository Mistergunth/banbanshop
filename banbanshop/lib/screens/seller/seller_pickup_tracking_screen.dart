// lib/screens/seller/seller_pickup_tracking_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
// ignore: unused_import
import 'package:location/location.dart' as loc;

class SellerPickupTrackingScreen extends StatefulWidget {
  final Order order;

  const SellerPickupTrackingScreen({super.key, required this.order});

  @override
  State<SellerPickupTrackingScreen> createState() =>
      _SellerPickupTrackingScreenState();
}

class _SellerPickupTrackingScreenState extends State<SellerPickupTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  PolylinePoints polylinePoints = PolylinePoints();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _routeInfo = 'กำลังรอสัญญาณจากลูกค้า...';
  BuyerProfile? _buyerProfile;
  Store? _store;
  LatLng? _buyerLocation;

  bool _isLoading = true;

  final String _googleApiKey = "AIzaSyCPW7zj9TLXyCtiZGMPOxIeWnIeAL7njKY";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await _fetchStoreAndBuyer();
      _addStoreMarker();
      _listenToOrderUpdates();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
          _routeInfo = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
        });
      }
    }
  }

  Future<void> _fetchStoreAndBuyer() async {
    try {
      final storeDoc = await FirebaseFirestore.instance.collection('stores').doc(widget.order.storeId).get();
      if (storeDoc.exists) _store = Store.fromFirestore(storeDoc);

      final buyerDoc = await FirebaseFirestore.instance.collection('buyers').doc(widget.order.buyerId).get();
      if (buyerDoc.exists) _buyerProfile = BuyerProfile.fromFirestore(buyerDoc);

    } catch (e) {
      print("Error fetching data: $e");
      rethrow;
    }
  }

  void _addStoreMarker() {
    if (_store?.latitude == null || _store?.longitude == null) return;
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('storeLocation'),
        position: LatLng(_store!.latitude!, _store!.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'ร้านของฉัน: ${_store!.name}'),
      ));
    });
  }

  void _listenToOrderUpdates() {
    final orderRef = FirebaseFirestore.instance
        .collection('stores')
        .doc(widget.order.storeId)
        .collection('orders')
        .doc(widget.order.id);

    _orderSubscription = orderRef.snapshots().listen((snapshot) async {
      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final status = OrderStatusExtension.fromString(data['status'] ?? 'shipped');

      if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
        _orderSubscription?.cancel();
        Navigator.of(context).pop();
        return;
      }

      if (data.containsKey('buyerLocation') && data['buyerLocation'] is GeoPoint) {
        final geoPoint = data['buyerLocation'] as GeoPoint;
        _buyerLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
        await _updateBuyerMarkerAndRoute(_buyerLocation!);
      }
    });
  }

  Future<void> _updateBuyerMarkerAndRoute(LatLng buyerPosition) async {
    final buyerIcon = await _createCustomMarkerBitmap(_buyerProfile?.profileImageUrl, Colors.teal);

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'buyerLocation');
      _markers.add(Marker(
        markerId: const MarkerId('buyerLocation'),
        position: buyerPosition,
        icon: buyerIcon,
        infoWindow: InfoWindow(title: 'ลูกค้า: ${_buyerProfile?.fullName}'),
        anchor: const Offset(0.5, 0.5),
      ));
    });

    if (_store?.latitude != null) {
      final storePosition = LatLng(_store!.latitude!, _store!.longitude!);
      await _drawRoute(buyerPosition, storePosition);
    }
    _fitBounds();
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
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
                _routeInfo = 'ลูกค้าอยู่ห่าง: $distance (ประมาณ $duration)';
              });
            }
          }
        } else {
           if (mounted) setState(() => _routeInfo = 'ไม่สามารถคำนวณเส้นทางได้');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _routeInfo = 'เกิดข้อผิดพลาดในการคำนวณเส้นทาง');
    }
  }

  void _fitBounds() {
    if (_mapController == null || _markers.isEmpty) return;

    var positions = _markers.map((m) => m.position).toList();
    if (positions.isEmpty) return;

    if (positions.length == 1) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(positions.first, 15.0));
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100.0));
  }
  
  Future<void> _callBuyer() async {
    if (_buyerProfile?.phoneNumber == null || _buyerProfile!.phoneNumber!.isEmpty) return;
    String phoneNumber = _buyerProfile!.phoneNumber!;
    if (phoneNumber.length == 9 && !phoneNumber.startsWith('0')) {
      phoneNumber = '0$phoneNumber';
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
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

  Future<BitmapDescriptor> _createCustomMarkerBitmap(String? imageUrl, Color borderColor) async {
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
        final icon = Icons.person;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามลูกค้ามารับสินค้า'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitBounds();
                  },
                  initialCameraPosition: _getInitialCameraPosition(),
                  markers: _markers,
                  polylines: _polylines,
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
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: (_buyerProfile?.profileImageUrl != null) ? NetworkImage(_buyerProfile!.profileImageUrl!) : null,
                        child: (_buyerProfile?.profileImageUrl == null) ? const Icon(Icons.person) : null,
                      ),
                      title: Text(_buyerProfile?.fullName ?? 'ลูกค้า', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text(_routeInfo, style: const TextStyle(fontSize: 16)),
                      trailing: IconButton(
                        onPressed: _callBuyer,
                        icon: const Icon(Icons.call, color: Colors.green, size: 30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
