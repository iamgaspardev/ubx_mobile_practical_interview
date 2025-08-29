import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({super.key});

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authStatus = 'Not authenticated';

  Future<void> _authenticate() async {
    try {
      bool isAuthenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _authStatus = isAuthenticated ? 'Authenticated' : 'Failed to authenticate';
      });

      if (isAuthenticated) {
        // Navigate to home or another page after successful auth
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _authenticate(); 
}

  @override
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric Authentication')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_authStatus),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }}