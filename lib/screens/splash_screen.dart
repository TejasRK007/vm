import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'guard_scan_screen.dart';
import 'visitor_self_register_screen.dart';
import 'host_approval_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && auth.isAuthenticated && auth.role != null) {
        // User is already logged in with valid role, navigate to appropriate screen
        Widget nextScreen;
        switch (auth.role) {
          case 'guard':
            nextScreen = const GuardScanScreen();
            break;
          case 'visitor':
            nextScreen = const VisitorSelfRegisterScreen();
            break;
          case 'host':
            nextScreen = const HostApprovalScreen();
            break;
          case 'admin':
          case 'receptionist':
          default:
            nextScreen = const DashboardScreen();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      } else {
        // No user logged in or missing role, go to login screen
        if (currentUser != null) {
          // Sign out user if they don't have proper role data
          await FirebaseAuth.instance.signOut();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error in splash screen auth check: $e');
      // On error, go to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850]!,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[800]!.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.security,
                  size: 80,
                  color: Colors.grey[300]!,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Visitor Management System',
                style: TextStyle(
                  color: Colors.grey[100]!,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Secure • Efficient • Professional',
                style: TextStyle(
                  color: Colors.grey[400]!,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[300]!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
