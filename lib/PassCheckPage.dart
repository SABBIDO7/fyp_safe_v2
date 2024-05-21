import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class PassCheckPage extends StatelessWidget {
  final RemoteMessage message;
  PassCheckPage({Key? key, required this.message}) : super(key: key);

  late MqttServerClient client;
  final TextEditingController _passwordController = TextEditingController();


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
                print("hon message ${message.data["password"]}");
                print("input value ${_passwordController.text}");
                if (message.data != null &&
                    message.notification != null && message.data["password"] == _passwordController.text) {
                  print("ana honnn ${message.data['password']}");
                  // Password matches the token
                  publishMQTTMessage("topicSafe/openSafe", "1");
                } else {
                  // Password doesn't match the token
                  print('Password is incorrect');
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> publishMQTTMessage(String topic, String payload) async {
    await _connect();
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
