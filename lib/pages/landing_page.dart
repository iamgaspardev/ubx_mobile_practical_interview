import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/pages/home_page.dart';
import 'package:ubx_practical_mobile/pages/user_profile_page.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/services/app_lockout_service.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  _LandingpageState createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  int _selectedIndex = 0;
  final AppLockoutService _lockoutService = AppLockoutService();

  final List<Widget> _pages = [const Homepage(), ProfilePageContent()];

  @override
  void initState() {
    super.initState();
    // Enable lockout when on homepage
    _updateLockoutStatus();
  }

  void _updateLockoutStatus() {
    if (_selectedIndex == 0) {
      _lockoutService.enableLockout();
    } else {
      _lockoutService.disableLockout();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _updateLastActiveTime(context);
      _updateLockoutStatus();
    });
  }

  void _updateLastActiveTime(BuildContext context) {
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );
    appLockProvider.updateLastActiveTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.green[100]),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),

            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey[400],
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
