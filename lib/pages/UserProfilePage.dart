// lib/pages/ProfilePage.dart
import 'package:flutter/material.dart';
import 'package:ubx_practical_mobile/widgets/ProfileOptions.dart';

class ProfilePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 243, 0, 0).withValues(alpha: 0.8),
                            Color.fromARGB(255, 200, 0, 0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(255, 243, 0, 0).withValues(alpha:0.3),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    Text(
                      'Gaspar Giddson',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      'gaspar.giddson.com',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Edit Profile tapped!'),
                            backgroundColor: Color.fromARGB(255, 243, 0, 0),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 243, 0, 0),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ProfileOption(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      subtitle: 'Update your details',
                      onTap: () => _showSnackBar(context, 'Personal Information tapped!'),
                    ),
                    
                    SizedBox(height: 12),
                    
                    ProfileOption(
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notifications',
                      onTap: () => _showSnackBar(context, 'Notifications tapped!'),
                    ),
                    
                    SizedBox(height: 30),

                    //logout Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 100), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color.fromARGB(255, 243, 0, 0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}