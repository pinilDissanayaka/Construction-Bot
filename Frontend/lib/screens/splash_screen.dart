import 'package:flutter/material.dart';
import 'package:rise/screens/chat_screen.dart';
import 'package:rise/screens/welcome_screen.dart';
import 'package:rise/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Add a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (isLoggedIn) {
      final userData = await AuthService.getUserData();
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userEmail: userData['email'] ?? '',
            userRole: userData['role'] ?? 'user',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      
      // Navigate to welcome screen if not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/rise_construction01.png',
              height: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: Color(0xFFE59412),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}