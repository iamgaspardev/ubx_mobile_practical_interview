import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/pages/Homepage.dart';
import 'package:ubx_practical_mobile/pages/LandingPage.dart';
import 'package:ubx_practical_mobile/pages/LoginPage.dart';
import 'package:ubx_practical_mobile/pages/RegisterPage.dart';
import 'package:ubx_practical_mobile/pages/BiometricAuthPage.dart';
import 'package:ubx_practical_mobile/pages/app_lock_screen.dart';
import 'package:ubx_practical_mobile/widgets/app_lifecycle_wrapper.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/providers/user_provider.dart';
import 'package:ubx_practical_mobile/services/api_service.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ApiService().initialize();
    print('ApiService initialized successfully');
  } catch (e) {
    print('Failed to initialize ApiService: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppLockProvider()),
        ChangeNotifierProvider(
          create: (context) => UserProvider()..initialize(),
        ),
      ],
      child: Consumer<AppLockProvider>(
        builder: (context, appLockProvider, child) {
          return MaterialApp(
            title: 'UBX Practical',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color.fromARGB(255, 243, 0, 0),
              ),
            ),
            home: _getInitialScreen(appLockProvider),
            builder: (context, child) {
              return AppLifecycleWrapper(child: child ?? const SizedBox());
            },
            routes: {
              '/home': (context) => const Homepage(),
              '/login': (context) => LoginPage(),
              '/register': (context) => RegistrationPage(),
              '/biometric': (context) => const BiometricAuthPage(),
              '/landingpage': (context) => const Landingpage(),
              '/applock': (context) => const AppLockScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AppLockProvider appLockProvider) {
    if (appLockProvider.isUserLoggedIn &&
        appLockProvider.isLocked &&
        !appLockProvider.isAuthenticated) {
      return const AppLockScreen();
    }

    if (appLockProvider.isUserLoggedIn && appLockProvider.isAuthenticated) {
      return const Landingpage();
    }

    return LoginPage();
  }
}
