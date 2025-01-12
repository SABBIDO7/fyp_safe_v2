import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp_safe/LiveStreamingPage.dart';
import 'package:fyp_safe/MapWidget.dart';
import 'package:fyp_safe/NotificationPage.dart';
import 'package:fyp_safe/RolePage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PassCheckPage.dart';
import 'PendingPage.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SignUpPage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initPushNotifications();
  runApp(const MyApp());
}

void handleMessage(RemoteMessage? message) {
  if (message == null) return;
  navigatorKey.currentState
      ?.pushNamed(NotificationPage.route, arguments: message);
}

Future<void> handleMessageBackground(RemoteMessage? message) async {
  print('Title: ${message?.notification?.title}');
  print('body: ${message?.notification?.body}');
  print('payload, ${message?.data}');
}

Future<void> initPushNotifications() async {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  FirebaseMessaging.onBackgroundMessage(handleMessageBackground);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green[700],
      ),
      home: AuthenticationWrapper(),
      routes: {
        NotificationPage.route: (context) => NotificationPage(),
        SignUpPage.route: (context) => SignUpPage(),
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkAuthentication(context),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ); // Show a loading indicator while checking authentication
        } else {
          if (snapshot.hasData) {
            // User is authenticated, navigate to appropriate page
            print("FETT HOME");
            if (snapshot.data["page"] == "home") {
              return MyHomePage();
            } else if (snapshot.data["page"] == "pending") {
              return PendingPage();
            } else {
              return RolePage();
            }
          } else {
            print("FETT ROLE");
            // User is not authenticated, show the login/signup page
            return RolePage();
          }
        }
      },
    );
  }

  Future<dynamic> _checkAuthentication(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    print("fettt honnnnn userrr $username");
    if (username != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final status = userData['status'];
        if (userData["role"] == 1) {
          return {"page": "home", "status": true};
        } else if (status == 'pending' || status == 'accepted') {
          // User status is pending, navigate to the PendingPage
          // Navigator.of(context).pushReplacement(
          //     MaterialPageRoute(builder: (context) => PendingPage()));
          return {"page": "pending", "status": true};
        } else {
          //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PassCheckPage()));
          // User status is not pending, return true
          return {"page": "role", "status": false};
        }
      } else {
        // User details not found, handle accordingly (e.g., navigate to a default page)
        // You can add your custom logic here
        return {"page": "role", "status": false};
      }
    } else {
      // If the user is not authenticated, return false
      return {"page": "role", "status": false};
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAFE'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text('Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapWidget()),
                );
              },
              child: const Text('Maps'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LiveStreamingPage()),
                );
              },
              child: const Text('Live'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<QuerySnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    _userStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        backgroundColor: Colors.green[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _userStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.pink,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No users are trying to access the SAFE'),
            );
          } else {
            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                print("Data from Firestore: $data");
                String username =
                    data['username'] ?? ''; // null check for username
                String imageUrl =
                    data['userUrl'] ?? ''; // null check for imageUrl

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    title: Text(username),
                    // Add more widgets here if needed
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
