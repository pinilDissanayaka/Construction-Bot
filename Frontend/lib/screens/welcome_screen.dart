import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rise/screens/chat_screen.dart';
import 'package:rise/services/auth_service.dart';
import 'login_&_signup.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  // Top image animation controller
  late final AnimationController _topController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );

  // Bottom image animation controller
  late final AnimationController _bottomController = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );

  // Top image animations
  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 0.3,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _topController, curve: Curves.easeOutBack));

  late final Animation<double> _opacityAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _topController, curve: Curves.easeIn));

  // Bottom image animations
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _bottomController, curve: Curves.easeOutCubic));

  late final Animation<double> _bottomFadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _bottomController, curve: Curves.easeIn));

  @override
void initState() {
  super.initState();
  // Start top animation immediately
  _topController.forward();
  
  // Start bottom animation with delay
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      _bottomController.forward();
    }
  });

  // Check auth status after animations
  Future.delayed(const Duration(seconds: 5), () async {
    if (!mounted) return;
    
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (isLoggedIn) {
      final userData = await AuthService.getUserData();
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            userEmail: userData['email'] ?? '',
            userRole: userData['role'] ?? 'user',
          ),
        ),
      );
    } else {
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginSignupScreen(),
        ),
      );
    }
  });
}

  @override
  void dispose() {
    _topController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top animated logo
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _topController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(
                            _opacityAnimation.value * 0.3,
                          ),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white.withOpacity(0.2),
                            BlendMode.srcATop,
                          ),
                          child: Image.asset(
                            "assets/images/rise_construction01.png",
                            width: 100,
                            height: 119.21,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom animated logo
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _bottomFadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Make the column take minimum space
                children: [
                  const SizedBox(height: 2), // Reduced from 5 to 2 for closer spacing
                  Text(
                    'POWERED BY',
                    style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 107, 107, 107),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      "assets/images/casasdasdas.png",
                      width: 144.05,
                      height: 144.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}