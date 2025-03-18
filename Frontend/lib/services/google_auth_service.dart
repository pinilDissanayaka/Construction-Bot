import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rise/services/auth_service.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Google and return user data
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in process
        return {'success': false, 'error': 'Sign in cancelled by user'};
      }

      try {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential authResult = await _auth.signInWithCredential(credential);
        final User? user = authResult.user;

        if (user != null) {
          // Save user session locally
          await AuthService.saveUserSession(
            email: user.email ?? googleUser.email,
            role: 'user', // Default role for Google sign-in users
            displayName: user.displayName ?? googleUser.displayName,
          );

          // Return success with user data
          return {
            'success': true,
            'email': user.email ?? googleUser.email,
            'displayName': user.displayName ?? googleUser.displayName,
            'role': 'user',
          };
        } else {
          return {'success': false, 'error': 'Failed to sign in with Google'};
        }
      } catch (firebaseError) {
        // Handle Firebase-specific errors but allow sign-in to proceed with Google account info
        print("Firebase authentication error: $firebaseError");
        
        // Save user session with just Google account info
        await AuthService.saveUserSession(
          email: googleUser.email,
          role: 'user',
          displayName: googleUser.displayName,
        );
        
        // Return success with Google user data
        return {
          'success': true,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'role': 'user',
        };
      }
    } catch (error) {
      return {'success': false, 'error': error.toString()};
    }
  }

  // Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Error during sign out: $e");
    } finally {
      await AuthService.logout();
    }
  }
}
