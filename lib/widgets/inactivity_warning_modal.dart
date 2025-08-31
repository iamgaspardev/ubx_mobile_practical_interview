import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'dart:async';

class InactivityWarningModal extends StatefulWidget {
  final int countdownSeconds;

  const InactivityWarningModal({Key? key, this.countdownSeconds = 10})
    : super(key: key);

  @override
  _InactivityWarningModalState createState() => _InactivityWarningModalState();
}

class _InactivityWarningModalState extends State<InactivityWarningModal>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    // Setup pulse animation for urgency
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
    _pulseController.repeat(reverse: true);
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _countdownTimer?.cancel();
          // Let provider handle the timeout - NO NAVIGATOR CALLS
          final appLockProvider = Provider.of<AppLockProvider>(
            context,
            listen: false,
          );
          appLockProvider.lockApp();
        }
      }
    });
  }

  void _handleContinue() {
    _countdownTimer?.cancel();

    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );
    appLockProvider.dismissInactivityWarning();
  }

  @override
  void dispose() {
    if (!_isDisposed) {
      _countdownTimer?.cancel();
      _pulseController.dispose();
      _isDisposed = true;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _remainingSeconds <= 3 ? _pulseAnimation.value : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 3 ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  'Inactivity Detected',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 12),

                // Message
                Text(
                  'You\'ve been inactive for a while.\nDo you want to continue using the app?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Countdown Timer
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _remainingSeconds <= 3
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _remainingSeconds <= 3
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_remainingSeconds',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds <= 3
                                ? Colors.green
                                : Colors.black87,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: TextStyle(
                            fontSize: 12,
                            color: _remainingSeconds <= 3
                                ? Colors.green
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Warning message for final countdown
                if (_remainingSeconds <= 3)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'App will lock automatically!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Yes, Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

                // Info text
                Text(
                  'Tap "Yes, Continue" to keep using the app',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
