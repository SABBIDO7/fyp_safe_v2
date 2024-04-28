import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'SignUpPage.dart';

class RolePage extends StatelessWidget {
  const RolePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message =
    ModalRoute.of(context)!.settings.arguments as RemoteMessage?;
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Role'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Save the value 1 for Admin
                saveRoleAndNavigateToSignUpPage(context, 1);
              },
              child: Text('Admin'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save the value 0 for User
                saveRoleAndNavigateToSignUpPage(context, 0);
              },
              child: Text('User'),
            ),
          ],
        ),
      ),
    );
  }

  // Function to save role value and navigate to SignUpPage
  void saveRoleAndNavigateToSignUpPage(BuildContext context, int role) {
    //String roleValue = role.toString();
    Navigator.pushNamed(context, SignUpPage.route, arguments: role);
  }
}
