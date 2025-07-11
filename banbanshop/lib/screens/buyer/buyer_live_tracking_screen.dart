// lib/screens/buyer/buyer_live_tracking_screen.dart

import 'dart:async';
import 'dart:convert'; // --- [KEY FIX] Add this import ---
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:banbanshop/screens/models/order_model.dart';
import 'package:banbanshop/screens/models/store_model.dart';
import 'package:banbanshop/screens/models/buyer_profile.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class BuyerLiveTrackingScreen extends StatefulWidget {
  final Order order;

  const BuyerLiveTrackingScreen({super.key, required this.order});

  @override
  State<BuyerLiveTrackingScreen> createState() =>
      _BuyerLiveTrackingScreenState();
}

class _BuyerLiveTrackingScreenState extends State<BuyerLiveTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  PolylinePoints polylinePoints = PolylinePoints();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _statusMessage = 'กำลังรอสัญญาณจากคนส่งของ...';
  String _routeInfo = '';
  Store? _store;
  BuyerProfile? _buyerProfile;

  // IMPORTANT: Replace with your own Google Maps API Key for Directions API
  // สำคัญ: กรุณาแทนที่ด้วย Google Maps API Key ของคุณ
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
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.order.storeId)
          .get();
      if (storeDoc.exists) {
        _store = Store.fromFirestore(storeDoc);
      }

      final buyerDoc = await FirebaseFirestore.instance
          .collection('buyers')
          .doc(widget.order.buyerId)
          .get();
      if (buyerDoc.exists) {
        _buyerProfile = BuyerProfile.fromFirestore(buyerDoc);
      }
      
      _listenToOrderUpdates();

    } catch (e) {
      print("Error fetching initial data: $e");
      if (mounted) {
        setState(() {
          _statusMessage = "เกิดข้อผิดพลาดในการโหลดข้อมูล";
        });
      }
    }
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
      
      if (status == OrderStatus.delivered) {
        setState(() {
          _statusMessage = 'จัดส่งสำเร็จแล้ว!';
          _routeInfo = '';
          _polylines.clear();
        });
        _orderSubscription?.cancel();
        return;
      }
      if (status == OrderStatus.cancelled) {
        setState(() => _statusMessage = 'การจัดส่งถูกยกเลิก');
        _orderSubscription?.cancel();
        return;
      }

      if (data.containsKey('delivererLocation') &&
          data['delivererLocation'] is GeoPoint) {
        final geoPoint = data['delivererLocation'] as GeoPoint;
        await _updateMarkersAndRoute(geoPoint);
        if (status == OrderStatus.shipped) {
          setState(() => _statusMessage = 'คนส่งของกำลังเดินทาง...');
        }
      }
    });
  }

  Future<void> _updateMarkersAndRoute(GeoPoint delivererGeoPoint) async {
    final delivererPosition =
        LatLng(delivererGeoPoint.latitude, delivererGeoPoint.longitude);
    final destinationPosition = widget.order.shippingLocation != null
        ? LatLng(widget.order.shippingLocation!.latitude,
            widget.order.shippingLocation!.longitude)
        : null;

    final delivererIcon =
        await _createCustomMarkerBitmap(_store?.imageUrl, Colors.redAccent);
    final destinationIcon =
        await _createCustomMarkerBitmap(_buyerProfile?.profileImageUrl, Colors.greenAccent);

    final Set<Marker> updatedMarkers = {};

    updatedMarkers.add(Marker(
      markerId: const MarkerId('deliverer'),
      position: delivererPosition,
      icon: delivererIcon,
      anchor: const Offset(0.5, 0.5),
      infoWindow: InfoWindow(title: 'คนส่ง: ${_store?.name}'),
    ));

    if (destinationPosition != null) {
      updatedMarkers.add(Marker(
        markerId: const MarkerId('destination'),
        position: destinationPosition,
        icon: destinationIcon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: const InfoWindow(title: 'ที่อยู่ของฉัน'),
      ));
    }

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(updatedMarkers);
      });
    }

    if (destinationPosition != null) {
      await _drawRoute(delivererPosition, destinationPosition);
    }
  }

  // --- [KEY FIX] Replaced method to call Directions API directly ---
  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$_googleApiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['routes'] != null && jsonResponse['routes'].isNotEmpty) {
          final route = jsonResponse['routes'][0];
          final leg = route['legs'][0];
          final distance = leg['distance']['text'];
          final duration = leg['duration']['text'];
          
          final overviewPolyline = route['overview_polyline']['points'];
          final List<PointLatLng> points = polylinePoints.decodePolyline(overviewPolyline);
          
          if (points.isNotEmpty) {
            List<LatLng> polylineCoordinates = points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
            
            if (mounted) {
              setState(() {
                _polylines.clear();
                _polylines.add(Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.blueAccent,
                  width: 5,
                  points: polylineCoordinates,
                ));
                _routeInfo = 'ระยะทาง: $distance (ประมาณ $duration)';
              });
            }
          }
        } else {
           print('Directions API response missing routes.');
        }
      } else {
        print('Directions API request failed with status: ${response.statusCode}');
      }
      _fitBounds(origin, destination);
    } catch (e) {
      print("Error in _drawRoute: $e");
    }
  }

  void _fitBounds(LatLng deliverer, LatLng? destination) {
    if (_mapController == null || destination == null) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        deliverer.latitude < destination.latitude
            ? deliverer.latitude
            : destination.latitude,
        deliverer.longitude < destination.longitude
            ? deliverer.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        deliverer.latitude > destination.latitude
            ? deliverer.latitude
            : destination.latitude,
        deliverer.longitude > destination.longitude
            ? deliverer.longitude
            : destination.longitude,
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
  }

  Future<BitmapDescriptor> _createCustomMarkerBitmap(
      String? imageUrl, Color borderColor) async {
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
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: icon.fontFamily))
          ..pushStyle(ui.TextStyle(color: Colors.grey[600], fontSize: 80.0))
          ..addText(String.fromCharCode(icon.codePoint));
        final paragraph = builder.build()..layout(ui.ParagraphConstraints(width: size.toDouble()));
        canvas.drawParagraph(paragraph, Offset((size - paragraph.width) / 2, (size - paragraph.height) / 2));
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
        title: Text('ติดตามออเดอร์ #${widget.order.id.substring(0, 8).toUpperCase()}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.7563, 100.5018),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                    if (_routeInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _routeInfo,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const Divider(height: 20),
                    const Text('จัดส่งไปที่:',
                        style: TextStyle(color: Colors.grey)),
                    Text(
                      widget.order.shippingAddress,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
