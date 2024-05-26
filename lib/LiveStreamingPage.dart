import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:web_socket_channel/io.dart';

class LiveStreamingPage extends StatefulWidget {
  @override
  _LiveStreamingPageState createState() => _LiveStreamingPageState();
}

class _LiveStreamingPageState extends State<LiveStreamingPage> {
  final channel = IOWebSocketChannel.connect('ws://192.168.1.106:8888');
  late MqttServerClient client;
  late StreamSubscription _subscription;
  Uint8List? _imageData;

  Future<void> _connect() async {
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);

    try {
      await client.connect();
      await publishMQTTMessage("topicSafe/liveStreaming", "1");

      print('Connected');
    } catch (e) {
      print('Exception: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _connect();
    print("ATA3IT L CONNECT");
    _subscription = channel.stream.listen((data) {
      setState(() {
        _imageData = data;
      });
    });

    // Fetch snapshot every 2000ms
    Timer.periodic(Duration(milliseconds: 6000), (timer) {
      if (mounted) {
        setState(() {});
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streaming'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: _imageData != null
            ? Image.memory(_imageData!)
            : CircularProgressIndicator(),
      ),
    );
  }

  @override
  void dispose() async {
    _subscription.cancel();
    channel.sink.close();
    await publishMQTTMessage("topicSafe/liveStreaming", "0");
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
