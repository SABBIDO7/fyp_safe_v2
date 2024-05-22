import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Import your home page widget
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController _emailController = TextEditingController();
    TextEditingController _passwordController = TextEditingController();

    void _navigateToHomePage(BuildContext context) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyHomePage()),
        (Route<dynamic> route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
        backgroundColor: Colors.green[700], // Adjust color as needed
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Sign in the user using FirebaseAuth
                  UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  // Get the signed-in user
                  User? user = userCredential.user;
                  print("User Creds from sign in ${user!.email}");
                  if (user.email != null) {
                    print("le2a email");
                    QuerySnapshot querySnapshot = await FirebaseFirestore
                        .instance
                        .collection('userDetails')
                        .where('email', isEqualTo: user.email)
                        .get();
                    if (querySnapshot.docs.isNotEmpty) {
                      // User found, retrieve status

                      final prefs = await SharedPreferences.getInstance();

                      String username = querySnapshot.docs.first['username'];
                      print("le2a l user------- $username");
                      prefs.setString('username', username);
                      prefs.setString(
                          'email', querySnapshot.docs.first['email']);
                      prefs.setString(
                          'role', querySnapshot.docs.first['role'].toString());
                    }
                  }

                  // Navigate to the home page or any other action
                  _navigateToHomePage(context);
                } catch (e) {
                  // Handle sign-in errors
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('Failed to sign in: $e'),
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
                }
              },
              child: Text('Sign In'),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context); // Navigate back to the previous page (SignUpPage)
              },
              child: Text(
                  'Create an Account'), // You can adjust the text as needed
            ),
          ],
        ),
      ),
    );
  }
}
