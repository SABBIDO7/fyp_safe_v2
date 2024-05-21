import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fyp_safe/PassCheckPage.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class NotificationPage extends StatelessWidget {
  NotificationPage({Key? key}) : super(key: key);
  static const route = '/notification-screen';
  late MqttServerClient client;

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
    final message =
    ModalRoute.of(context)!.settings.arguments as RemoteMessage?;
    if (message != null && message.notification != null) {
      if (message.notification!.title != null &&
          message.notification!.title! == 'Response Accepted') {
        // If title contains 'Enter Your Password', navigate to PassCheckPage
        return PassCheckPage(message:message); // Assuming PassCheckPage is a StatelessWidget
      } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notification'),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  message.notification!.title ?? 'No Title',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  message.notification!.body ?? 'No Body',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),

              // Display the image from the notification message
              if (message.notification!.android != null)
                Image.network(
                  message.notification!.android!.imageUrl ?? '',
                  // Provide a placeholder image or loading indicator
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircularProgressIndicator();
                  },
                  // Adjust width and height as needed
                  width: 200,
                  height: 200,
                ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async{
                      // Publish MQTT message for accept with payload '1'
                      if (message != null &&
                          message.notification != null &&
                          message.notification!.title != null &&
                          message.notification!.title!.contains('Registration')) {
                        String? username = message.data['username'];
                        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
                            .collection('userDetails')
                            .where('username', isEqualTo: username)
                            .get();

                        if (querySnapshot.docs.isNotEmpty) {
                          //Access the first (and only) document directly
                          DocumentSnapshot doc = querySnapshot.docs.first;
                          //Update the status field
                          await doc.reference.update({'status': 'accepted'});
                        } else {
                          print('No document found for username: $username');
                        }
                        Map<String, dynamic> payloadMap = {
                          'username': username,
                          'status': 'Accepted',
                        };
                        String payloadString = jsonEncode(payloadMap);
                        publishMQTTMessage('topicSafe/UserRegistration', payloadString);
                      }else{
                        String? username = message.data['username'];
                        Map<String, dynamic> payloadMap = {
                          'username': username,
                          'status': 'Accepted',
                        };
                        String payloadString = jsonEncode(payloadMap);
                        print("anaa fetettttttttt $username");
                      publishMQTTMessage('topicSafe/AccessAuthorization', payloadString);
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Publish MQTT message for accept with payload '1'
                      if (message != null &&
                          message.notification != null &&
                          message.notification!.title != null &&
                          message.notification!.title!.contains('Registration')) {
                        Map<String, dynamic> payloadMap = {
                          'username': '',
                          'status': 'Rejected',
                        };
                        String payloadString = jsonEncode(payloadMap);
                        publishMQTTMessage('topicSafe/UserRegistration', payloadString);

                      }else{
                        Map<String, dynamic> payloadMap = {
                          'username': '',
                          'status': 'Rejected',
                        };
                        String payloadString = jsonEncode(payloadMap);
                        publishMQTTMessage('topicSafe/AccessAuthorization', payloadString);
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Decline'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }} else {
      // Handle the case when message or message.notification is null
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
        ),
        body: Center(
          child: Text('Invalid Notification'),
        ),
      );
    }
  }

  // Function to publish MQTT message
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
