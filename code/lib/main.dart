import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import your login screen
//import 'dart:ui'; // This imports FontFeature


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(), // Call your Login UI here
    );
  }
}
