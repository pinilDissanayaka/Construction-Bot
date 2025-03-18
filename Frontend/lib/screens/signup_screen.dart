import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:rise/screens/chat_screen.dart';
import 'package:rise/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const String _apiUrl =
      'https://e52d-122-255-33-126.ngrok-free.app/auth/register';

  // Constants for responsive design
  static const double kTabletBreakpoint = 768.0;
  static const double kDesktopBreakpoint = 1024.0;

  // Form key and state variables
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _autoValidateMode = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Handle sign up
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidateMode = true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _fullNameController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _confirmPasswordController.text.trim(),
          'role': 'user',
        }),
      );

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save user session after successful signup
        final userEmail = _emailController.text.trim();
        const userRole = 'user';

        await AuthService.saveUserSession(email: userEmail, role: userRole);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Account created successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to chat screen with user data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    ChatScreen(userEmail: userEmail, userRole: userRole),
          ),
        );
      } else {
        // Your existing error handling
        String errorMessage;
        if (responseData is Map<String, dynamic>) {
          errorMessage =
              responseData['detail'] ??
              responseData['message'] ??
              'Registration failed. Please try again.';
        } else {
          errorMessage = 'Registration failed. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed:
                  () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      // Your existing catch block
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Validation methods
  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Include at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Include at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Account',
          style: GoogleFonts.tenorSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: getResponsivePadding(context),
            child: Form(
              key: _formKey,
              autovalidateMode:
                  _autoValidateMode
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 20),
                  ),
                  _buildTextFormField(
                    context,
                    controller: _fullNameController,
                    hintText: 'Full Name',
                    prefixIcon: Icons.person_outline,
                    validator: _validateFullName,
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 15),
                  ),
                  _buildTextFormField(
                    context,
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmail,
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 15),
                  ),
                  _buildTextFormField(
                    context,
                    controller: _phoneController,
                    hintText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: _validatePhone,
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 15),
                  ),
                  _buildTextFormField(
                    context,
                    controller: _passwordController,
                    hintText: 'Create Password',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 15),
                  ),
                  _buildTextFormField(
                    context,
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    prefixIcon: Icons.lock_outline,
                    validator: _validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed:
                          () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                    ),
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 25),
                  ),
                  _buildButton(
                    context,
                    text: 'Sign Up',
                    onPressed: _isLoading ? null : _handleSignUp,
                    isLoading: _isLoading,
                  ),
                  SizedBox(
                    height: getResponsiveFontSize(context, baseFontSize: 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.tenorSans(
                          color: Colors.grey,
                          fontSize: getResponsiveFontSize(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: GoogleFonts.tenorSans(
                            color: const Color(0xFFE59412),
                            fontSize: getResponsiveFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
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
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Color(0xFFE59412), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
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
        errorStyle: GoogleFonts.tenorSans(
          color: Colors.red[300],
          fontSize: getResponsiveFontSize(context, baseFontSize: 12),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE59412),
        disabledBackgroundColor: Colors.grey,
        padding: EdgeInsets.symmetric(
          vertical: getResponsiveFontSize(context, baseFontSize: 12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child:
          isLoading
              ? SizedBox(
                height: getResponsiveFontSize(context, baseFontSize: 20),
                width: getResponsiveFontSize(context, baseFontSize: 20),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(
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
}
