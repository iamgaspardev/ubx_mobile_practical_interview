import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

class AppLockProvider with ChangeNotifier {
  bool _isLocked = false;
  bool _isAuthenticated = false;
  bool _isUserLoggedIn = false;
  bool _showingInactivityWarning = false;
  DateTime? _lastActiveTime;
  Timer? _inactivityTimer;
  BuildContext? _currentContext;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final Duration inactivityTimeout = Duration(seconds: 30);
  final Duration warningPeriod = Duration(seconds: 10);

  // Getters
  bool get isLocked => _isLocked;
  bool get isAuthenticated => _isAuthenticated;
  bool get isUserLoggedIn => _isUserLoggedIn;
  bool get showingInactivityWarning => _showingInactivityWarning;
  //this ia to controll image processing
  bool _imageProcessingActive = false;
  bool get isImageProcessingActive => _imageProcessingActive;

  void setImageProcessingActive(bool active) {
    _imageProcessingActive = active;
    notifyListeners();
    if (active) {
      //  App lock disabled for image processing
    } else {
      //  App lock re-enabled after image processing
      updateLastActiveTime();
    }
  }

  void setCurrentContext(BuildContext context) {
    _currentContext = context;
  }

  void setUserLoggedIn() {
    _isUserLoggedIn = true;
    _isAuthenticated = true;
    _isLocked = false;
    print("User logged in - starting app lock monitoring");
    updateLastActiveTime();
    notifyListeners();
  }

  void setUserLoggedOut() {
    _isUserLoggedIn = false;
    _isAuthenticated = false;
    _isLocked = false;
    _showingInactivityWarning = false;
    _cancelInactivityTimer();
    print("User logged out - stopping app lock monitoring");
    notifyListeners();
  }

  void lockApp() {
    if (!_isUserLoggedIn) {
      print("Ignoring lock - user not logged in yet");
      return;
    }

    // Don't lock if image processing is active
    if (_imageProcessingActive) {
      return;
    }

    _isLocked = true;
    _isAuthenticated = false;
    _showingInactivityWarning = false;
    _lastActiveTime = DateTime.now();
    _cancelInactivityTimer();
    print("App locked");
    notifyListeners();
  }

  void unlockApp() {
    _isLocked = false;
    _isAuthenticated = true;
    _showingInactivityWarning = false;
    _lastActiveTime = DateTime.now();
    _startInactivityTimer();
    print("App unlocked - staying on current page");
    notifyListeners();
  }

  void updateLastActiveTime() {
    if (!_isUserLoggedIn) {
      print("Ignoring activity - user not logged in yet");
      return;
    }

    _lastActiveTime = DateTime.now();

    // If app was locked due to inactivity, unlock it when user becomes active
    if (_isLocked && _isAuthenticated) {
      _isLocked = false;
    }

    // Hide warning if showing
    if (_showingInactivityWarning) {
      _showingInactivityWarning = false;
      notifyListeners();
    }

    _startInactivityTimer();
    print("User activity detected");
  }

  void onAppBackgrounded() {
    if (!_isUserLoggedIn) {
      return;
    }

    // Don't lock if image processing is active
    if (_imageProcessingActive) {
      return;
    }

    lockApp();
  }

  void onAppForegrounded() {
    print("App foregrounded");
    if (_isUserLoggedIn && !_isLocked && !_isAuthenticated) {
      _startInactivityTimer();
    }
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();

    Duration warningDelay = inactivityTimeout - warningPeriod;

    _inactivityTimer = Timer(warningDelay, () {
      _showInactivityWarning();
    });
  }

  void _showInactivityWarning() {
    if (!_isUserLoggedIn || _showingInactivityWarning) return;

    // Don't show warning if image processing is active
    if (_imageProcessingActive) {
      return;
    }

    _showingInactivityWarning = true;
    notifyListeners();

    // Start countdown timer for the warning
    Timer(warningPeriod, () {
      if (_showingInactivityWarning) {
        _showingInactivityWarning = false;
        lockApp();
      }
    });
  }

  void dismissInactivityWarning() {
    if (!_showingInactivityWarning) return;

    _showingInactivityWarning = false;
    updateLastActiveTime();
    notifyListeners();
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<bool> authenticate({
    String reason = 'Please authenticate to continue',
  }) async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return await _authenticateWithDeviceCredentials(reason);
      }

      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return await _authenticateWithDeviceCredentials(reason);
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        print("🔓 Authentication successful - unlocking app");
        unlockApp();
        return true;
      }
      print("🔓 Authentication failed");
      return false;
    } on PlatformException catch (e) {
      print('Authentication error: ${e.message}');
      return false;
    }
  }

  Future<bool> _authenticateWithDeviceCredentials(String reason) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        unlockApp();
        return true;
      }
      return false;
    } catch (e) {
      print('Device credential authentication error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    super.dispose();
  }
}
