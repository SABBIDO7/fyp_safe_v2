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
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Colors.green[700],
      ),
      home: AuthenticationWrapper(),
      routes: {NotificationPage.route: (context) =>  NotificationPage(),
        SignUpPage.route: (context) =>  SignUpPage(),
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
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show a loading indicator while checking authentication
        } else {
          if (snapshot.hasData && snapshot.data!) {
            // User is authenticated, navigate to appropriate page
            return MyHomePage();
          } else {
            // User is not authenticated, show the login/signup page
            return RolePage();
          }
        }
      },
    );
  }

  Future<bool> _checkAuthentication(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('username', isEqualTo: username)
          .where('role', isEqualTo: 0)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final status = userData['status'];

        if (status == 'pending') {
          // User status is pending, navigate to the PendingPage
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PendingPage()));
          return false;
        } else {
          //Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PassCheckPage()));
          // User status is not pending, return true
          return false;
        }
      } else {
        // User details not found, handle accordingly (e.g., navigate to a default page)
        // You can add your custom logic here
        return false;
      }
    } else {
      // If the user is not authenticated, return false
      return false;
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [HomePage(), MapWidget(), LiveStreamingPage()];
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAFE'),
        backgroundColor: Colors.green[700],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green[700],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.maps_home_work),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'Live',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    return StreamBuilder<QuerySnapshot>(
      stream: _userStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
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
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              print("Data from Firestore: $data");
              String username = data['username'] ?? ''; // null check for username
              String imageUrl = data['userUrl'] ?? ''; // null check for imageUrl

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
    );
  }
}
