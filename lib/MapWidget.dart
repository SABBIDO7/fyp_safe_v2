import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController mapController;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  LatLng? _center;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    _listenToLatLng();
  }

  void _listenToLatLng() {
    _database.child('/').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final lat = data['LAT'] as double?;
        final lng = data['LNG'] as double?;
        if (lat != null && lng != null) {
          setState(() {
            _center = LatLng(lat, lng);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _center == null
        ? Center(child: CircularProgressIndicator())
        : GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center!,
        zoom: 50.0,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('Sydney'),
          position: _center!,
          infoWindow: const InfoWindow(
            title: "Sydney",
            snippet: "Capital of New South Wales",
          ),
        ),
      },
    );
  }
}
