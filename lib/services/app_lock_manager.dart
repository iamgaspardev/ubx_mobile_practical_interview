import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:async';

class AppLockManager {
  static final AppLockManager _instance = AppLockManager._internal();
  factory AppLockManager() => _instance;
  AppLockManager._internal();

  bool _isLocked = false;
  bool _isAuthenticated = false;
  DateTime? _lastActiveTime;
  Timer? _inactivityTimer;
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Inactivity timeout
  final Duration inactivityTimeout = Duration(seconds: 30);
  
  // Warning period before locking
  final Duration warningPeriod = Duration(seconds: 10);
  
  // Callback for showing inactivity warning
  Function(BuildContext context, Function onContinue, Function onTimeout)? onShowInactivityWarning;
  
  // Store current context for modal display
  BuildContext? _currentContext;
  
  // Callback to trigger UI rebuild when lock state changes
  VoidCallback? _onLockStateChanged;

  bool get isLocked => _isLocked;
  bool get isAuthenticated => _isAuthenticated;

  void lockApp() {
    _isLocked = true;
    _isAuthenticated = false;
    _lastActiveTime = DateTime.now();
    _cancelInactivityTimer();
    
    // Trigger UI rebuild
    if (_onLockStateChanged != null) {
      _onLockStateChanged!();
    }
  }

  void unlockApp() {
    _isLocked = false;
    _isAuthenticated = true;
    _lastActiveTime = DateTime.now();
    _startInactivityTimer();
  }

  void updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
    
    if (_isLocked && _isAuthenticated) {
      _isLocked = false;
    }
    
    _startInactivityTimer();
  }

  // Called when app goes to background - IMMEDIATE LOCK
  void onAppBackgrounded() {
    // print(" App backgrounded - locking immediately");
    lockApp();
  }

  // Called when app comes to foreground
  void onAppForegrounded() {
    // Don't automatically unlock - require authentication
    if (_isLocked && !_isAuthenticated) {
      // Keep locked, authentication required
    } else {
      // Start inactivity timer
      _startInactivityTimer();
    }
  }

  void setInactivityWarningCallback(Function(BuildContext context, Function onContinue, Function onTimeout) callback) {
    onShowInactivityWarning = callback;
    print("🔧 Inactivity warning callback set: ${callback != null}");
  }
  
  void setCurrentContext(BuildContext context) {
    _currentContext = context;
    print("🔧 Current context set: ${context != null}");
  }
  
  void setLockStateChangeCallback(VoidCallback callback) {
    _onLockStateChanged = callback;
    print("🔧 Lock state change callback set");
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    
    // inactivityTimeout - warningPeriod
    Duration warningDelay = inactivityTimeout - warningPeriod;
    
    print("🕐 Starting inactivity timer with ${warningDelay.inSeconds} seconds delay");
    
    _inactivityTimer = Timer(warningDelay, () {
      
      // Show warning modal if callback is set
      if (onShowInactivityWarning != null && _currentContext != null) {
        // print("All conditions met - showing modal");
        onShowInactivityWarning!(
          _currentContext!,
          () {
            // User chose to continue
            // print("User chose to continue");
            updateLastActiveTime();
          },
          () {
            // Warning timeout - close app
            _closeApp();
          },
        );
      } else {
        lockApp();
      }
    });
  }

  void _closeApp() {
    // For now, we will just lock it
    lockApp();
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<bool> authenticate({String reason = 'Please authenticate to continue'}) async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return await _authenticateWithDeviceCredentials(reason);
      }

      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();

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
        unlockApp();
        return true;
      }
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

  void dispose() {
    _cancelInactivityTimer();
  }
}