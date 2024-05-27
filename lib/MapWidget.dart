import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';

class MapWidget extends StatefulWidget {
  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MqttServerClient client;
  late GoogleMapController mapController;
  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  LatLng? _center;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _connect() async {
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);

    try {
      await client.connect();
      await publishMQTTMessage("topicSafe/gps", "1");

      print('Connected');
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();

    _listenToLatLng();
  }

  Future<void> _initialize() async {
    await _connect();
    print("Connected to MQTT, waiting before starting WebSocket...");
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps'),
        backgroundColor: Colors.green[700],
      ),
      body: _center == null
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
            ),
    );
  }

  @override
  void dispose() async {
    await publishMQTTMessage("topicSafe/gps", "0");
    super.dispose();
  }

  Future<void> publishMQTTMessage(String topic, String payload) async {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload); // Use the provided payload
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        await client.publishMessage(
            topic, MqttQos.exactlyOnce, builder.payload!);
        print('Payload published successfully');
      } catch (e) {
        print('Error publishing payload: $e');
      }
    } else {
      print('Error: MQTT client is not connected');
    }
  }
}
