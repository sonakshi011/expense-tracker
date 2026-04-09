import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'auth/auth_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseAuth.instance.authStateChanges().listen((user) async {
  //   final auth = FirebaseAuth.instance;
  //
  //   if (await auth.isSignInWithEmailLink(
  //     Uri.base.toString(),
  //   )) {
  //     final prefs = await SharedPreferences.getInstance();
  //     String email = prefs.getString('email') ?? '';
  //
  //     await auth.signInWithEmailLink(
  //       email: email,
  //       emailLink: Uri.base.toString(),
  //     );
  //   }
  // });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}
