import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingPage extends StatelessWidget {
  const PendingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getUserStatus(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Pending'),
              backgroundColor: Colors.orange, // Customize the app bar color
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Pending'),
              backgroundColor: Colors.orange, // Customize the app bar color
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          String userStatus = snapshot.data ?? '';
          if (userStatus == 'pending') {
            return Scaffold(
              appBar: AppBar(
                title: Text('Pending'),
                backgroundColor: Colors.orange, // Customize the app bar color
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending, // Use an appropriate icon for pending status
                      size: 100,
                      color: Colors.orange, // Customize the icon color
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Your account is pending approval.',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please wait for admin approval to access the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text('Pending'),
                backgroundColor: Colors.orange, // Customize the app bar color
              ),
              body: Center(
                child: Text(
                  'You have been accepted.',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Future<String> _getUserStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    if (username != null) {
      // Query userDetails collection in Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // User found, retrieve status
        String userStatus = querySnapshot.docs.first['status'];
        return userStatus;
      }
    }
    // Default to 'pending' if username not found or status not available
    return 'pending';
  }
}
