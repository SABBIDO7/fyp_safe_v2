import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fyp_safe/PendingPage.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class PassCheckPage extends StatefulWidget {
  final RemoteMessage message;
  PassCheckPage({Key? key, required this.message}) : super(key: key);

  @override
  _PassCheckPageState createState() => _PassCheckPageState();
}

class _PassCheckPageState extends State<PassCheckPage> {
  late MqttServerClient client;
  final TextEditingController _passwordController = TextEditingController();
  bool _showLockButton = false;

  Future<void> _connect() async {
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);

    try {
      await client.connect();
      print('Connected');
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<void> publishMQTTMessage(String topic, String payload) async {
    await _connect();
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
        print('Payload published successfully');
      } catch (e) {
        print('Error publishing payload: $e');
      }
    } else {
      print('Error: MQTT client is not connected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password Check'),
        backgroundColor: Colors.blue, // Adjust color as needed
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please enter your password to continue:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _passwordController, // Assign the controller here
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("hon message ${widget.message.data["password"]}");
                print("input value ${_passwordController.text}");
                if (widget.message.notification != null &&
                    widget.message.data["password"] ==
                        _passwordController.text) {
                  print("ana honnn ${widget.message.data['password']}");
                  // Password matches the token
                  publishMQTTMessage("topicSafe/openSafe", "1").then((_) {
                    setState(() {
                      _showLockButton = true;
                    });
                  });
                } else {
                  // Password doesn't match the token
                  print('Password is incorrect');
                }
              },
              child: Text('Submit'),
            ),
            SizedBox(height: 20),
            if (_showLockButton)
              ElevatedButton(
                onPressed: () {
                  publishMQTTMessage("topicSafe/openSafe", "0").then((_) {
                    setState(() {
                      _showLockButton = false;
                    });
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const PendingPage()),
                      (Route<dynamic> route) => false,
                    );
                  });
                },
                child: Text('Lock Safe'),
              ),
          ],
        ),
      ),
    );
  }
}
