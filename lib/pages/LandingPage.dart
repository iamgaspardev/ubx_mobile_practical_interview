import 'package:flutter/material.dart';
import 'package:ubx_practical_mobile/pages/Homepage.dart';
import 'package:ubx_practical_mobile/pages/UserProfilePage.dart';
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
      _lockoutService.enableLockout();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _updateLockoutStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
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
