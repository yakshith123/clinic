import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }

  // Method to get user details from Google sign-in
  static Future<Map<String, dynamic>?> getUserDetails() async {
    final GoogleSignInAccount? currentUser = _googleSignIn.currentUser;
    if (currentUser != null) {
      return {
        'id': currentUser.id,
        'email': currentUser.email,
        'name': currentUser.displayName,
        'photoUrl': currentUser.photoUrl,
      };
    }
    return null;
  }

  // Helper method to generate a random password
  static String _generateRandomPassword() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*(),./;:?';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Method to register or login user via Google in our backend
  static Future<Map<String, dynamic>?> registerOrLoginGoogleUser(Map<String, dynamic>? googleUserDetails) async {
    if (googleUserDetails == null) return null;

    try {
      // Prepare user data for registration/login
      final userData = {
        'email': googleUserDetails['email'],
        'name': googleUserDetails['name'],
        'password': _generateRandomPassword(), // Generate a random password for Google users
        'phone': '', // Phone can be empty for Google users initially
        'role': 'patient', // Default role for Google users
        'is_google_user': true, // Mark as Google user
      };

      // Make API call to register/login user
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8001/api/auth/register'), // Backend URL for emulator
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // User registered/logged in successfully
        return jsonDecode(response.body);
      } else if (response.statusCode == 409) {
        // User already exists, try to login
        final loginResponse = await http.post(
          Uri.parse('http://10.0.2.2:8001/api/auth/login'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': googleUserDetails['email'], // Use email as username
            'password': userData['password'], // Use the generated password
          }),
        );
        
        if (loginResponse.statusCode == 200) {
          return jsonDecode(loginResponse.body);
        }
      }

      return null;
    } catch (e) {
      print('Error registering/logging in Google user: $e');
      return null;
    }
  }
}