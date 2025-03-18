import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Keys for storing data
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userDisplayNameKey = 'user_display_name';

  // Save user session after login or signup
  static Future<void> saveUserSession({
    required String email, 
    required String role,
    String? displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userRoleKey, role);
    await prefs.setBool(_isLoggedInKey, true);
    
    // Save display name if provided
    if (displayName != null && displayName.isNotEmpty) {
      await prefs.setString(_userDisplayNameKey, displayName);
    }
  }

  // Update user display name
  static Future<void> saveUserDisplayName(String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDisplayNameKey, displayName);
  }

  // Get the logged in user data
  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_userEmailKey),
      'role': prefs.getString(_userRoleKey),
      'displayName': prefs.getString(_userDisplayNameKey),
    };
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Log out user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userDisplayNameKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}