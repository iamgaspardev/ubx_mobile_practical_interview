import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ubx_practical_mobile/pages/register_page.dart';
import 'package:ubx_practical_mobile/services/app_lockout_service.dart';
import 'package:ubx_practical_mobile/services/api_service.dart';
import 'package:ubx_practical_mobile/widgets/Input_widget.dart';
import 'package:ubx_practical_mobile/widgets/other_signin_button.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSavedCredentials();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(0.2, 1.0, curve: Curves.elasticOut),
          ),
        );

    _animationController.forward();
  }

  void _loadSavedCredentials() {
    // Pre-fill for testing (remove in production)
    // _emailController.text = 'test@example.com';
    // _passwordController.text = 'password123';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Check if user has previously logged in and has biometric enabled
      if (!userProvider.isAuthenticated) {
        _showMessage(
          'Please login with email and password first to enable biometric authentication',
          MessageType.info,
        );
        return;
      }

      final bool isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        _showMessage(
          'Biometric authentication is not available on this device',
          MessageType.warning,
        );
        return;
      }

      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        _showMessage(
          'No biometric methods are set up on this device',
          MessageType.warning,
        );
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account securely',
        options: AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        _showMessage(
          'Biometric authentication successful!',
          MessageType.success,
        );

        // Mark user as logged in
        final appLockProvider = Provider.of<AppLockProvider>(
          context,
          listen: false,
        );
        appLockProvider.setUserLoggedIn();

        _navigateToLandingPage();
      } else {
        _showMessage(
          'Biometric authentication was cancelled',
          MessageType.info,
        );
      }
    } on Exception catch (e) {
      print("Biometric authentication error: $e");
      _showMessage(
        'Biometric authentication failed: ${e.toString()}',
        MessageType.error,
      );
    }
  }

  void _navigateToLandingPage() {
    if (mounted) {
      AppLockoutService().reset();
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/landingpage', (route) => false);
    }
  }

  void _showMessage(String message, MessageType type) {
    if (!mounted) return;

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case MessageType.error:
        backgroundColor = Colors.green;
        icon = Icons.error;
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange;
        icon = Icons.warning;
        break;
      case MessageType.info:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Haptic feedback
    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await userProvider.login(email: email, password: password);

    if (success) {
      _showMessage('Welcome back! Login successful', MessageType.success);

      // This is for Remembering
      if (_rememberMe) {
        //
      }

      // Mark user as logged in
      final appLockProvider = Provider.of<AppLockProvider>(
        context,
        listen: false,
      );
      appLockProvider.setUserLoggedIn();

      // Small delay to show success message
      await Future.delayed(Duration(milliseconds: 1500));

      _navigateToLandingPage();
    } else {
      final errorMsg =
          userProvider.errorMessage ?? 'Login failed. Please try again.';
      _showMessage(errorMsg, MessageType.error);

      // Clear password field on failed login
      _passwordController.clear();

      // Haptic feedback for error
      HapticFeedback.heavyImpact();
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegistrationPage(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final emailController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_reset, color: Colors.green[400]),
              SizedBox(width: 8),
              Text('Reset Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we\'ll send you a password reset link.',
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement password reset
                Navigator.pop(context);
                _showMessage(
                  'Password reset feature coming soon!',
                  MessageType.info,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Send Reset Link',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 60),

                        // App Logo/Icon
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.green[400],
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.business_center,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 40),

                        // Welcome Text
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sign in to continue to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: 48),

                        // Email Input
                        InputWidget(
                          hintText: 'Email address',
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address';
                            }
                            if (!RegExp(
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        // Password Input
                        InputWidget(
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          controller: _passwordController,
                          isPassword: true,
                          enabled: !userProvider.isLoading,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: userProvider.isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                  activeColor: Colors.green[400],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            TextButton(
                              onPressed: userProvider.isLoading
                                  ? null
                                  : _handleForgotPassword,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.green[400],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: userProvider.isLoading
                                ? null
                                : _performLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                            ),
                            child: userProvider.isLoading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Signing in...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        // Login Button
                        // Container(
                        //   width: double.infinity,
                        //   height: 56,
                        //   child: ElevatedButton(
                        //     onPressed: userProvider.isLoading
                        //         ? null
                        //         : _performLogin,
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.green[400],
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(16),
                        //       ),
                        //       elevation: 0,
                        //       shadowColor: Colors.green[400].withOpacity(0.3),
                        //     ),
                        //     child: userProvider.isLoading
                        //         ? Row(
                        //             mainAxisAlignment: MainAxisAlignment.center,
                        //             children: [
                        //               SizedBox(
                        //                 width: 20,
                        //                 height: 20,
                        //                 child: CircularProgressIndicator(
                        //                   color: Colors.white,
                        //                   strokeWidth: 2,
                        //                 ),
                        //               ),
                        //               SizedBox(width: 12),
                        //               Text(
                        //                 'Signing in...',
                        //                 style: TextStyle(
                        //                   fontSize: 16,
                        //                   fontWeight: FontWeight.w600,
                        //                   color: Colors.white,
                        //                 ),
                        //               ),
                        //             ],
                        //           )
                        //         : Text(
                        //             'Sign In',
                        //             style: TextStyle(
                        //               fontSize: 18,
                        //               fontWeight: FontWeight.w600,
                        //               color: Colors.white,
                        //             ),
                        //           ),
                        //   ),
                        // ),
                        SizedBox(height: 32),

                        // Sign Up Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: userProvider.isLoading
                                        ? null
                                        : _navigateToRegister,
                                    child: Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: userProvider.isLoading
                                            ? Colors.grey
                                            : Colors.green[400],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Biometric Authentication Section
                        SizedBox(height: 24),

                        FutureBuilder<bool>(
                          future: _localAuth.canCheckBiometrics,
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return Column(
                                children: [
                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(color: Colors.grey[300]),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'Or continue with',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(color: Colors.grey[300]),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 24),

                                  Container(
                                    width: 64,
                                    height: 64,
                                    child: Material(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(32),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(32),
                                        onTap: userProvider.isLoading
                                            ? null
                                            : _authenticateWithBiometrics,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              32,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.fingerprint,
                                            size: 32,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),

                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum MessageType { success, error, warning, info }
