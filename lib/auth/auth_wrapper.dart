import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {


        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;


        if (user == null) {
          return const LoginScreen();
        }

        final bool isGoogleUser = user.providerData
            .any((info) => info.providerId == 'google.com');

        if (!user.emailVerified && !isGoogleUser) {

          // FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }


        return const HomeScreen();
      },
    );
  }
}