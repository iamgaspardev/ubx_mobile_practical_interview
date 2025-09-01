import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ubx_practical_mobile/providers/app_lock_provider.dart';
import 'package:ubx_practical_mobile/widgets/ProfileOptions.dart';
import 'package:ubx_practical_mobile/providers/user_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  void _updateLastActiveTime(BuildContext context) {
    final appLockProvider = Provider.of<AppLockProvider>(
      context,
      listen: false,
    );
    appLockProvider.updateLastActiveTime();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "UBX Interview",
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.green, Colors.greenAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 8.0,
                              left: 8,
                              right: 8,
                            ),
                            child: Text(
                              "Hi Mr..",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 0),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: userProvider.isLoading
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Loading...",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    userProvider.getUserDisplayName(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                          ),
                          // Optional: Show email below name
                          if (userProvider.user?.email != null &&
                              !userProvider.isLoading)
                            Padding(
                              padding: EdgeInsets.only(
                                left: 8.0,
                                right: 8.0,
                                top: 4.0,
                              ),
                              child: Text(
                                userProvider.user!.email!,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          ProfileOption(
                            icon: Icons.wallet,
                            title: 'BigData Management',
                            subtitle: 'Manage your Bigdata',
                            onTap: () => _updateLastActiveTime(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
