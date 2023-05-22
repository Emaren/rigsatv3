import 'package:flutter/material.dart';
import 'login_page.dart';
import 'sign_up_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      theme: ThemeData(
        primarySwatch: Colors.teal,
        // theme: ThemeData(
        // primaryColor: Color.fromARGB(255, 13, 6, 150),
      ),
      routes: {
        '/signup': (BuildContext context) => const SignUpPage(),
        '/login': (BuildContext context) => const LoginPage(),
      },
    );
  }

  Future<void> onLogout() async {
    // Implement your logout functionality here
  }
}
