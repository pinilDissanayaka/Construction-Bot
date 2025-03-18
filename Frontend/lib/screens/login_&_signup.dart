import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rise/screens/chat_screen.dart';
import 'package:rise/screens/signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rise/services/auth_service.dart';
import 'package:rise/services/google_auth_service.dart';  // Add this import

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen>
    with TickerProviderStateMixin {
  // Constants
  static const _animationDuration = Duration(milliseconds: 300);
  static const double kTabletBreakpoint = 768.0;
  static const double kDesktopBreakpoint = 1024.0;
  static const String _apiUrl =
      'https://e52d-122-255-33-126.ngrok-free.app/auth/login';

  // Screen state
  bool _showLogin = false;
  bool _isLoading = false;
  bool _isGoogleSigningIn = false;  // Add this variable
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  // Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Messages for animated text
  final List<String> _messages = [
    'Material Estimation',
    'Safety Guidelines',
    'Project Timeline',
    'Cost Analysis',
    'Equipment Guide',
    'Building Codes',
    'Site Planning',
    'Quality Control',
    'Contract Review',
  ];

  // Add this method for Google sign-in
  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleSigningIn) return;

    setState(() => _isGoogleSigningIn = true);

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (result['success']) {
        // Navigate to the chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userEmail: result['email'],
              userRole: result['role'],
            ),
          ),
        );
      } else {
        _showErrorSnackBar(result['error'] ?? 'Google sign-in failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    // Validate inputs
    setState(() {
      _emailError = _validateEmail(_loginEmailController.text);
      _passwordError = _validatePassword(_loginPasswordController.text);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _loginEmailController.text.trim(),
          'password': _loginPasswordController.text,
        }),
      );

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save the user session
        final userEmail = _loginEmailController.text.trim();
        final userRole = responseData['role'];

        await AuthService.saveUserSession(email: userEmail, role: userRole);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(userEmail: userEmail, userRole: userRole),
          ),
        );
      } else if (response.statusCode == 401) {
        _showErrorSnackBar(responseData['message'] ?? 'please try again');
      } else {
        _showErrorSnackBar(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Helper methods for responsive design
  double getResponsiveWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= kDesktopBreakpoint) {
      return screenWidth * 0.4;
    } else if (screenWidth >= kTabletBreakpoint) {
      return screenWidth * 0.6;
    }
    return screenWidth;
  }

  double getResponsiveFontSize(
    BuildContext context, {
    double baseFontSize = 14.0,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= kDesktopBreakpoint) {
      return baseFontSize * 1.5;
    } else if (screenWidth >= kTabletBreakpoint) {
      return baseFontSize * 1.25;
    }
    return baseFontSize;
  }

  EdgeInsets getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= kDesktopBreakpoint) {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.1, vertical: 20);
    } else if (screenWidth >= kTabletBreakpoint) {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 15);
    }
    return const EdgeInsets.symmetric(horizontal: 25, vertical: 15);
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final availableHeight = size.height - padding.top - padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Animated text
                Positioned(
                  left: 0,
                  right: 0,
                  height: availableHeight * 0.25,
                  child: Container(
                    padding: getResponsivePadding(context),
                    child: Center(
                      child: SizedBox(
                        width: getResponsiveWidth(context) * 0.7,
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: 'TenorSans',
                            color: const Color(0xFFE59412),
                            fontSize: getResponsiveFontSize(
                              context,
                              baseFontSize: 30,
                            ),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: const [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.white38,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                          child: AnimatedTextKit(
                            repeatForever: true,
                            pause: const Duration(milliseconds: 1000),
                            animatedTexts:
                                _messages
                                    .map(
                                      (message) => TypewriterAnimatedText(
                                        message,
                                        speed: const Duration(
                                          milliseconds: 100,
                                        ),
                                        curve: Curves.easeOut,
                                      ),
                                    )
                                    .toList(),
                            displayFullTextOnTap: true,
                            stopPauseOnTap: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Login/Welcome Container (no scroll)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    constraints: BoxConstraints(
                      minHeight:
                          _showLogin
                              ? availableHeight * 0.45
                              : availableHeight * 0.35,
                      maxWidth: getResponsiveWidth(context),
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal:
                          size.width > kTabletBreakpoint ? size.width * 0.1 : 0,
                    ),
                    padding: getResponsivePadding(context),
                    decoration: BoxDecoration(
                      color: const Color(0xFF474747).withOpacity(0.95),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        AnimatedOpacity(
                          opacity: !_showLogin ? 1.0 : 0.0,
                          duration: _animationDuration,
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: _showLogin,
                            child: _buildWelcomeView(context),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _showLogin ? 1.0 : 0.0,
                          duration: _animationDuration,
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: !_showLogin,
                            child: _buildLoginForm(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: getResponsiveFontSize(context, baseFontSize: 20),
              ),
              onPressed: () => setState(() => _showLogin = false),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                'Login',
                style: GoogleFonts.tenorSans(
                  fontSize: getResponsiveFontSize(context, baseFontSize: 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: getResponsiveFontSize(context, baseFontSize: 28)),
          ],
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 15)),
        _buildTextField(
          context,
          controller: _loginEmailController,
          hintText: 'Email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          errorText: _emailError,
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 10)),
        _buildTextField(
          context,
          controller: _loginPasswordController,
          hintText: 'Password',
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          errorText: _passwordError,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 15)),
        _buildButton(
          context,
          text: _isLoading ? 'Logging in...' : 'Login',
          onPressed: _isLoading ? null : _handleLogin,
        ),
      ],
    );
  }

  Widget _buildWelcomeView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome',
          style: GoogleFonts.tenorSans(
            fontSize: getResponsiveFontSize(context, baseFontSize: 20),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 12)),
        _buildButton(
          context,
          text: 'Sign Up',
          onPressed: () {
            // Navigate to the SignupScreen instead of showing the inline form
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 8)),
        _buildOutlinedButton(
          context,
          text: 'Log In',
          onPressed: () => setState(() => _showLogin = true),
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Container(height: 1, color: Colors.grey.withOpacity(0.5)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getResponsiveFontSize(context, baseFontSize: 10),
              ),
              child: Text(
                'Or continue with',
                style: GoogleFonts.tenorSans(
                  color: Colors.grey,
                  fontSize: getResponsiveFontSize(context, baseFontSize: 12),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.grey.withOpacity(0.5)),
            ),
          ],
        ),
        SizedBox(height: getResponsiveFontSize(context, baseFontSize: 12)),
        _buildGoogleSignInButton(context),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText && _obscurePassword,
      style: GoogleFonts.tenorSans(
        color: Colors.white,
        fontSize: getResponsiveFontSize(context),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.tenorSans(
          color: Colors.grey,
          fontSize: getResponsiveFontSize(context),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.tenorSans(
          color: Colors.red[300],
          fontSize: getResponsiveFontSize(context, baseFontSize: 12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: getResponsiveFontSize(context, baseFontSize: 16),
          vertical: getResponsiveFontSize(context, baseFontSize: 10),
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.grey,
          size: getResponsiveFontSize(context, baseFontSize: 20),
        ),
        suffixIcon: suffixIcon,
        isDense: true,
      ),
      onChanged:
          (_) => setState(() {
            if (controller == _loginEmailController) {
              _emailError = null;
            } else if (controller == _loginPasswordController) {
              _passwordError = null;
            }
          }),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            onPressed == null ? Colors.grey : const Color(0xFFE59412),
        padding: EdgeInsets.symmetric(
          vertical: getResponsiveFontSize(context, baseFontSize: 12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        text,
        style: GoogleFonts.tenorSans(
          color: Colors.white,
          fontSize: getResponsiveFontSize(context),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: getResponsiveFontSize(context, baseFontSize: 12),
        ),
        side: const BorderSide(color: Colors.white, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.tenorSans(
          fontSize: getResponsiveFontSize(context),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Update the Google sign-in button to call our method
  Widget _buildGoogleSignInButton(BuildContext context) {
    return OutlinedButton(
      onPressed: _isGoogleSigningIn ? null : _handleGoogleSignIn,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          vertical: getResponsiveFontSize(context, baseFontSize: 10),
        ),
        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isGoogleSigningIn
              ? SizedBox(
                  height: getResponsiveFontSize(context, baseFontSize: 20),
                  width: getResponsiveFontSize(context, baseFontSize: 20),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Image.asset(
                  'assets/images/google_logo.png',
                  height: getResponsiveFontSize(context, baseFontSize: 20),
                  width: getResponsiveFontSize(context, baseFontSize: 20),
                ),
          SizedBox(width: getResponsiveFontSize(context, baseFontSize: 8)),
          Text(
            _isGoogleSigningIn ? 'Signing in...' : 'Continue with Google',
            style: GoogleFonts.tenorSans(
              fontSize: getResponsiveFontSize(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
