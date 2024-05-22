import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camera/camera.dart';
import 'package:fyp_safe/PendingPage.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'SignInPage.dart';
import 'main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);
  static const route = '/signup-screen';
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late MqttServerClient client;
  late CameraController _controller;
  List<Uint8List> _capturedImages = [];
  static const int maxImages = 10;
  int _imageCount = 0;
  bool _showCameraPreview = false;
  bool _showCaptureButton = true;
  String _captureMessage = '';
  String? _errorMessage;
  int _currentStep = 0;
  var pongCount = 0;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String? _deviceToken;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    client = MqttServerClient('test.mosquitto.org', '1883');
    client.logging(on: false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final roleValue = ModalRoute.of(context)!.settings.arguments as int;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  Stepper(
                    currentStep: _showCameraPreview ? 1 : _currentStep,
                    onStepContinue: () async {
                      if (_currentStep == 0) {
                        // First step: validate fields and proceed
                        if (_validateFields()) {
                          setState(() {
                            _currentStep++;
                          });
                          _initCamera();
                        } else {
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_errorMessage!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else if (_currentStep == 1) {
                        if (!_showCaptureButton && _imageCount == maxImages) {
                          //await sendmQtt();
                          await _publishImages(roleValue);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Finish capturing first"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() {
                          _currentStep--;
                          _showCameraPreview = false;
                        });
                      } else {}
                    },
                    controlsBuilder:
                        (context, ControlsDetails controlsDetails) {
                      return Container(
                        child: Row(
                          children: [
                            if (_currentStep != 0)
                              Expanded(
                                child: TextButton(
                                  child: Text('BACK'),
                                  onPressed: controlsDetails.onStepCancel,
                                ),
                              ),
                            Expanded(
                              child: ElevatedButton(
                                child: Text('NEXT'),
                                onPressed: controlsDetails.onStepContinue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      Step(
                        title: Text('Enter Username, Email, and Password'),
                        isActive: !_showCameraPreview,
                        content: Container(
                          height: screenHeight *
                              0.4, // Set the height to 40% of the screen height
                          child: Column(
                            children: [
                              TextField(
                                controller: _usernameController,
                                decoration:
                                    InputDecoration(labelText: 'Username'),
                              ),
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(labelText: 'Email'),
                              ),
                              TextField(
                                controller: _passwordController,
                                decoration:
                                    InputDecoration(labelText: 'Password'),
                                obscureText: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: Text('Capture Images'),
                        isActive: _showCameraPreview,
                        content: Container(
                          height: screenHeight *
                              0.4, // Set the height to 40% of the screen height
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                if (_showCameraPreview)
                                  Column(
                                    children: [
                                      Container(
                                        height: screenHeight *
                                            0.4 *
                                            0.75, // 75% of the content container's height
                                        child: CameraPreview(_controller),
                                      ),
                                      Visibility(
                                        visible: _showCaptureButton,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (_imageCount < maxImages) {
                                              await _captureAndPublishImages();
                                            }
                                          },
                                          child: Text('Capture Image'),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        _captureMessage,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
                height:
                    20), // Add some space between the Stepper and the Sign In button

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInPage()),
                );
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateFields() {
    // Reset error message
    _errorMessage = null;

    // Check if username, email, and password fields are not empty
    if (_usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _errorMessage = 'Please fill in all fields.';
      return false;
    }

    // Check if email format is valid
    if (!_isValidEmail(_emailController.text)) {
      _errorMessage = 'Invalid email format.';
      return false;
    }

    // Check if password is strong enough
    if (!_isStrongPassword(_passwordController.text)) {
      _errorMessage = 'Password is too weak.';
      return false;
    }

    return true;
  }

  bool _isStrongPassword(String password) {
    // Minimum length for the password
    final minLength = 6; // Example: Minimum length of 6 characters

    return password.length >= minLength;
  }

  bool _isValidEmail(String email) {
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    CameraDescription? frontCamera;
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    if (frontCamera != null) {
      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller.initialize();
      setState(() {
        _showCameraPreview = true;
      });
    } else {
      print('No front camera found');
    }
  }

  Future<void> _captureAndPublishImages() async {
    setState(() {
      _showCaptureButton = false; // Hide the capture button
      _captureMessage = 'Hold on, change the angle of your face...';
    });
    for (int i = 0; i < maxImages; i++) {
      try {
        XFile imageFile = await _controller.takePicture();
        final Uint8List imageBytes = await File(imageFile.path).readAsBytes();
        _capturedImages.add(imageBytes);
        setState(() {
          _imageCount++; // Update _imageCount and rebuild the UI
        });
      } catch (e) {
        print('Error capturing image: $e');
      }
    }
    setState(() {
      _captureMessage = 'You can continue now';
    });
  }

  Future<void> _publishImages(int roleValue) async {
    await client.connect();

    // Check if the roleValue is admin
    if (roleValue == 1) {
      // Check if role 1 (admin) already exists
      final adminQuery = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('role', isEqualTo: 1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        // Role 1 (admin) already exists, show alert
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Admin exist'),
              content: Text(
                  'The safe already has an admin. You cannot sign up as an admin.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        return; // Exit the method
      }
    }

    // Continue with the rest of the sign-up process
    // Check if the username already exists
    final usernameQuery = await FirebaseFirestore.instance
        .collection('userDetails')
        .where('username', isEqualTo: _usernameController.text)
        .get();

    if (usernameQuery.docs.isNotEmpty) {
      // Username already exists, show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'The username already exists. Please choose a different username.'),
        ),
      );
      return; // Exit the method
    }

    // Save user details in Firebase Authentication
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      print('User registered: ${user!.uid}');
    } catch (e) {
      print('Error registering user: $e');
      // Handle error here
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _errorMessage =
                'The email address is already in use by another account.';
          });
        } else {
          setState(() {
            _errorMessage =
                'An unexpected error occurred. Please try again later.';
          });
        }
      }
    }

    // Save user details in Firestore
    String? _deviceToken = await _firebaseMessaging.getToken();

    Map<String, dynamic> userData = {
      'username': _usernameController.text,
      'email': _emailController.text,
      'role': roleValue,
      'token': _deviceToken,
      'urlImageRegister': '',
    };

// Add the status field if roleValue is 0
    if (roleValue == 0) {
      userData['status'] = 'pending';
    }

// Set user details in Firestore
    await FirebaseFirestore.instance.collection('userDetails').doc().set(
          userData,
          SetOptions(
            merge: true,
          ),
        );
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', _usernameController.text);
    prefs.setString('email', _emailController.text);
    prefs.setString('role', roleValue.toString());

    print('User details saved in Firestore');

    //Show dialog to inform user about successful sign-up
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Up Successful'),
          content: Text('You have successfully signed up.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                if (roleValue == 1) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => PendingPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    // // Publish images
    // images.forEach((imageBytes) {
    //   _publish(topic, imageBytes);
    // });.
    // Create a JSON object with username and image bytes

    // List to hold base64 images
    //  List<String> base64Images = [];
    //
    //  for (var imageBytes in _capturedImages) {
    //    final imageBase64 = base64Encode(imageBytes);
    //    base64Images.add(imageBase64);
    //  }
    // Split _capturedImages into two batches
    List<Uint8List> firstBatch = _capturedImages.sublist(0, 5);
    List<Uint8List> secondBatch = _capturedImages.sublist(5);
    // Publish the first batch
    await _connect();
    await _publishBatch(firstBatch, roleValue);
    // Publish the second batch
    await _publishBatch(secondBatch, roleValue);
  }

  Future<void> _publishBatch(List<Uint8List> images, int roleValue) async {
    List<String> base64Images =
        images.map((imageBytes) => base64Encode(imageBytes)).toList();

// Create a map with username and images
    Map<String, dynamic> payloadMap = {
      'username': _usernameController.text,
      'images': base64Images,
    };

    print('payloadMap, $payloadMap');
    print(
        '_capturedImages, ${_capturedImages.map((imageBytes) => base64Encode(imageBytes)).toList()}');
    // Convert the map to a JSON string
    String payloadJson = jsonEncode(payloadMap);
    print('payloadJSon, $payloadJson');
    //await _publish(topic, Uint8List.fromList(payloadString.codeUnits));
    // print("Publishing to topic: $topic");
    // final payloadBuffer = Uint8Buffer();
    // payloadBuffer.addAll(payload);
    final builder = MqttClientPayloadBuilder();

    builder.addString(payloadJson);
    //builder.addString(_usernameController.text);
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        if (roleValue == 1) {
          await client.publishMessage(
              "topicSafe/AdminTrain", MqttQos.exactlyOnce, builder.payload!);
        } else {
          await client.publishMessage(
              "topicSafe/UserTrain", MqttQos.exactlyOnce, builder.payload!);
        }
        // _capturedImages.forEach((imageBytes) {
        //   final payloadBuffer = Uint8Buffer();
        //   payloadBuffer.addAll(imageBytes);
        //   client.publishMessage("topicSafe/train", MqttQos.atMostOnce, payloadBuffer);
        // });
        print('Payload published successfully');
      } catch (e) {
        print('Error publishing payload: $e');
      }
    } else {
      print('Error: MQTT client is not connected');
    }
  }

  // void _navigateToHomePage(BuildContext context) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (context) => MyHomePage()),
  //   );
  // }
}
