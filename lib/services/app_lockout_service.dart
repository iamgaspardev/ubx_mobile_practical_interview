// ignore_for_file: avoid_print

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AppLockoutService {
  static final AppLockoutService _instance = AppLockoutService._internal();
  factory AppLockoutService() => _instance;
  AppLockoutService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLocked = false;
  bool _shouldLockOnBackground = false;

  bool get isLocked => _isLocked;

  void enableLockout() {
    _shouldLockOnBackground = true;
  }

  void disableLockout() {
    _shouldLockOnBackground = false;
    _isLocked = false;
  }

  void lockApp() {
    if (_shouldLockOnBackground) {
      _isLocked = true;
      print('App locked');
    }
  }

  Future<bool> unlockApp() async {
    if (!_isLocked) return true;

    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _isLocked = false;
        return true; // Skip authentication if not supported
      }

      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        _isLocked = false;
        return true;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        _isLocked = false;
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      print('Authentication error: ${e.message}');
      _isLocked = false;
      return true; // Allow access if there's an authentication error
    }
  }

  void reset() {
    _isLocked = false;
    _shouldLockOnBackground = false;
  }
}
