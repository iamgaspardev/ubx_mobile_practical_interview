import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/services/app_lockout_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({Key? key}) : super(key: key);

  @override
  _AppLockScreenState createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Automatically attempt authentication when lock screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !mounted) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    final appLockProvider = Provider.of<AppLockProvider>(context, listen: false);

    try {
      final bool success = await appLockProvider.authenticate(
        reason: 'Please authenticate to access UBX Practical'
      );

      if (!mounted) return;

      if (success) {
        // Authentication successful - navigate back to landing page
        print("Authentication successful - navigating to landing page");
        // Reset lockout service
        final lockoutService = AppLockoutService();
        lockoutService.reset();
        // Navigate back to landing page
        Navigator.of(context).pushNamedAndRemoveUntil('/landingpage', (route) => false);
      } else {
        // Authentication failed
        print("Authentication failed");
        _showAuthenticationFailedDialog();
      }
    } catch (e) {
      print("Authentication error: $e");
      if (mounted) {
        _showAuthenticationFailedDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  // Remove this method entirely - navigation should not happen from lock screen
  // void _navigateToLandingPage() {
  //   ...
  // }

  void _showAuthenticationFailedDialog() {
    if (!mounted) return;
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Authentication Failed'),
            content: const Text('Please try authenticating again to access the app.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Small delay to ensure dialog closes before retry
                  Future.delayed(Duration(milliseconds: 100), () {
                    if (mounted) {
                      _authenticate();
                    }
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error showing dialog: $e");
      // If dialog fails, just retry authentication after a delay
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _authenticate();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade800,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo or Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // App Name
                const Text(
                  'UBX Practical',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Authentication message
                const Text(
                  'App is locked for your security',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                
                // Authentication button or loading indicator
                if (_isAuthenticating)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Authenticating...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _authenticate,
                        icon: const Icon(Icons.fingerprint, color: Colors.white),
                        label: const Text(
                          'Authenticate',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to unlock with biometrics or device credentials',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}