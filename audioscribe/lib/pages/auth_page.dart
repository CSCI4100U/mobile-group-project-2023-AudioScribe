import 'package:audioscribe/pages/login_page.dart';
import 'package:audioscribe/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // user is logged in
            if (snapshot.hasData) {
              return MainPage();
            }

            // user is NOT logged in
            else {
              return const LoginPage();
            }
          }),
    );
  }
}
