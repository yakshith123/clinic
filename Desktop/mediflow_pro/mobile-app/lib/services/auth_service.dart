import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../models/user.dart' as ModelUser;
import 'api_service.dart';
import 'google_sign_in_service.dart'; // Import Google Sign-In service

class AuthService {
  static String? _authToken;
  static ModelUser.User? _currentUser;
  static bool _isInitialized = false;
  static SharedPreferences? _prefs;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _refreshTokenKey = 'refresh_token';

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await ApiService.initialize();
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved auth data
    _authToken = _prefs!.getString(_tokenKey);
    final refreshToken = _prefs!.getString(_refreshTokenKey);
    final userJson = _prefs!.getString(_userKey);
    
    if (userJson != null && _authToken != null) {
      try {
        final userData = Map<String, dynamic>.from(
          jsonDecode(userJson)
        );
        _currentUser = ModelUser.User.fromMap(userData);
        
        // Validate token by attempting to fetch user profile
        try {
          await getProfile();
        } catch (e) {
          print('Token validation failed: $e, clearing auth data');
          await _clearAuthData();
        }
      } catch (e) {
        print('Error loading saved user data: $e');
        await _clearAuthData();
      }
    }
    
    _isInitialized = true;
    print('Auth Service initialized. Authenticated: $isAuthenticated');
  }

  static bool get isAuthenticated => _authToken != null && _currentUser != null;

  static String? get authToken => _authToken;

  static ModelUser.User? get currentUser => _currentUser;

  static Map<String, String> getAuthHeaders() {
    if (_authToken == null) {
      return {};
    }
    return {
      'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    };
  }

  static Future<ModelUser.User?> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final response = await ApiService.login(email, password);
      
      _authToken = response['access_token'] as String?;
      // Handle refresh token if available
      if (response.containsKey('refresh_token')) {
        await _prefs!.setString(_refreshTokenKey, response['refresh_token'] as String);
      }
      
      // Extract user data from login response if available
      if (response.containsKey('user')) {
        final userData = response['user'] as Map<String, dynamic>;
        _currentUser = ModelUser.User.fromMap(userData);
      } else {
        // Get user profile to verify login
        final userResponse = await ApiService.getProfile();
        _currentUser = ModelUser.User.fromMap(userResponse);
      }
      
      // Save auth data
      await _saveAuthData();
      
      return _currentUser;
    } catch (e) {
      print('Sign in error: $e');
      // Don't clear auth data on login failure, just return null
      return null;
    }
  }

  // NEW: Google Sign-In method
  static Future<ModelUser.User?> signInWithGoogle() async {
    try {
      // Sign in with Google
      final googleUser = await GoogleSignInService.signInWithGoogle();
      if (googleUser == null) {
        return null; // User cancelled
      }

      // Get Google user details
      final googleUserData = await GoogleSignInService.getUserDetails();
      if (googleUserData == null) {
        return null;
      }

      // Register or login the user in our backend
      final backendResponse = await GoogleSignInService.registerOrLoginGoogleUser(googleUserData);
      if (backendResponse == null) {
        return null;
      }

      // Extract token from backend response
      _authToken = backendResponse['access_token'];
      if (backendResponse.containsKey('refresh_token')) {
        await _prefs!.setString(_refreshTokenKey, backendResponse['refresh_token']);
      }

      // Get user profile to complete setup
      final userResponse = await ApiService.getProfile();
      _currentUser = ModelUser.User.fromMap(userResponse);

      // Save auth data
      await _saveAuthData();

      return _currentUser;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  static Future<ModelUser.User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required ModelUser.UserRole role,
    String? hospitalId,
    List<String>? associatedClinicIds, // New parameter for multiple clinic associations - ignored for backend
    String? department,
    String? phone,
  }) async {
    try {
      final userData = {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone ?? '+1234567890',
        'role': role.toString().split('.').last.toLowerCase(),
        if (hospitalId != null && hospitalId.isNotEmpty) 'hospital_id': hospitalId,
        if (associatedClinicIds != null) 'associated_clinic_ids': associatedClinicIds,
        'department': department,
      };

      // Register the user
      final registerResponse = await ApiService.signup(userData);
      // Login to get the token
      final loginResponse = await ApiService.login(email, password);
      _authToken = loginResponse['access_token'] as String?;
      
      // Handle refresh token if available
      if (loginResponse.containsKey('refresh_token')) {
        await _prefs!.setString(_refreshTokenKey, loginResponse['refresh_token'] as String);
      }
      
      // Get user profile
      final userResponse = await ApiService.getProfile();
      _currentUser = ModelUser.User.fromMap(userResponse);
      // Save auth data
      await _saveAuthData();
      
      return _currentUser;
    } catch (e) {
      print('Sign up error: $e');
      // Propagate the actual error message to be caught by UI
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      // Only call backend logout if we have a valid token
      if (_authToken != null) {
        try {
          await ApiService.post('/auth/logout', {}, headers: getAuthHeaders());
        } catch (e) {
          print('Backend logout failed (this is OK): $e');
          // Continue with local logout even if backend fails
        }
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      // Always clear local auth data to ensure clean state
      await _clearAuthData();
      // Also sign out from Google
      await GoogleSignInService.signOut();
    }
  }

  static Future<void> refreshToken() async {
    try {
      final refreshToken = _prefs!.getString(_refreshTokenKey);
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await ApiService.post('/auth/refresh', {
        'refresh_token': refreshToken
      }, headers: getAuthHeaders());
      
      _authToken = response.data!['access_token'] as String?;
      if (response.data!.containsKey('refresh_token')) {
        await _prefs!.setString(_refreshTokenKey, response.data!['refresh_token'] as String);
      }
      
      await _saveAuthData();
    } catch (e) {
      print('Token refresh failed: $e');
      await _clearAuthData();
      rethrow;
    }
  }

  static Future<bool> isTokenValid() async {
    if (_authToken == null) return false;
    
    try {
      // Try to get user profile to verify token validity
      final response = await ApiService.get('/users/profile', headers: getAuthHeaders());
      if (response.statusCode == 200) {
        // Update current user with fresh data
        _currentUser = ModelUser.User.fromMap(response.data as Map<String, dynamic>);
        await _saveAuthData();
        return true;
      }
    } catch (e) {
      print('Token validation failed: $e');
    }
    return false;
  }

  static Future<void> _saveAuthData() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    if (_authToken != null && _currentUser != null) {
      await _prefs!.setString(_tokenKey, _authToken!);
      await _prefs!.setString(_userKey, jsonEncode(_currentUser!.toMap()));
    }
  }

  static Future<void> _clearAuthData() async {
    _prefs ??= await SharedPreferences.getInstance();
    
    _authToken = null;
    _currentUser = null;
    await _prefs!.remove(_tokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_userKey);
  }

  static Future<void> resetAuthData() async {
    await _clearAuthData();
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await ApiService.forgotPassword(email);
      return response;
    } catch (e) {
      print('Forgot password error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(String email, String otpCode) async {
    try {
      final response = await ApiService.verifyOTP(email, otpCode);
      return response;
    } catch (e) {
      print('Verify OTP error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    try {
      final response = await ApiService.requestOTP(phone);
      return response;
    } catch (e) {
      print('Request OTP error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneOTP(String phone, String otpCode) async {
    try {
      final response = await ApiService.verifyPhoneOTP(phone, otpCode);
      return response;
    } on DioException catch (e) {
      print('Verify Phone OTP DioException: $e');
      print('Response status code: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      
      // Extract error message from backend response
      if (e.response?.statusCode == 403 && e.response?.data != null) {
        final errorMessage = e.response!.data['detail'] ?? 
                            e.response!.data['message'] ?? 
                            'Phone number not registered. Please create an account first.';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 400 && e.response?.data != null) {
        final errorMessage = e.response!.data['detail'] ?? 
                            e.response!.data['message'] ?? 
                            'Invalid OTP or verification failed';
        throw Exception(errorMessage);
      }
      rethrow;
    } catch (e) {
      print('Verify Phone OTP error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> resetPasswordWithOtp(String email, String otpCode, String newPassword) async {
    try {
      final response = await ApiService.resetPassword(email, otpCode, newPassword);
      return response;
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // Add method to get profile that validates token
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await ApiService.getProfile();
      return response;
    } catch (e) {
      print('Error getting profile: $e');
      rethrow;
    }
  }
}