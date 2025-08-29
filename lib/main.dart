import 'package:flutter/material.dart';
import 'package:ubx_practical_mobile/pages/Homepage.dart';
import 'package:ubx_practical_mobile/pages/LandingPage.dart';
import 'package:ubx_practical_mobile/pages/LoginPage.dart';
import 'package:ubx_practical_mobile/pages/RegisterPage.dart';
import 'package:ubx_practical_mobile/pages/BiometricAuthPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UBX Practical',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 243, 0, 0)),
      ),
      initialRoute: '/login',
      routes: {
        '/home': (context) => const Homepage(),
        '/login': (context) =>  LoginPage(),
        '/register': (context) =>  RegistrationPage(),
        '/biometric': (context) => const BiometricAuthPage(),
        '/landingpage':(context) => Landingpage()
      },
    );
  }
}
