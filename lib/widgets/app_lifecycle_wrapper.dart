import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/pages/app_lock_screen.dart';
import 'package:ubx_practical_mobile/widgets/inactivity_warning_modal.dart';

class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  _AppLifecycleWrapperState createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        appLockProvider.onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        appLockProvider.onAppForegrounded();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      builder: (context, appLockProvider, child) {
        // Update context for provider
        appLockProvider.setCurrentContext(context);

        // FIRST PRIORITY: Show lock screen if user is logged in AND app is locked
        if (appLockProvider.isUserLoggedIn && appLockProvider.isLocked) {
          return const AppLockScreen();
        }

        // SECOND PRIORITY: Show inactivity warning as overlay if active
        if (appLockProvider.showingInactivityWarning) {
          return Scaffold(
            body: Stack(
              children: [
                widget.child,
                Container(
                  color: Colors.black54,
                  child: Center(child: InactivityWarningModal()),
                ),
              ],
            ),
          );
        }

        // DEFAULT: Show main app content
        return widget.child;
      },
    );
  }
}
