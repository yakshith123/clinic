import 'package:flutter/foundation.dart';
import 'dart:async'; // Add this import for Timer
import '../models/user.dart' as ModelUser;
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  ModelUser.User? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;
  bool _initialized = false;

  ModelUser.User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initializeAuthListener() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await AuthService.initialize();
      
      // Check if user is already authenticated
      if (AuthService.isAuthenticated) {
        _currentUser = AuthService.currentUser;
        // Setup notifications for existing user
        if (_currentUser != null) {
          await _setupUserNotifications(_currentUser!);
        }
      }
      
      _initialized = true;
      _isLoading = false;
      notifyListeners();
      
      // Set up periodic refresh
      // Don't set up timer if not authenticated
      if (_currentUser != null) {
        Timer.periodic(const Duration(minutes: 5), (timer) {
          if (_currentUser != null) {
            _refreshUserData();
          }
        });
      }
    } catch (e) {
      print('Error initializing auth service: $e');
      _errorMessage = 'Failed to initialize authentication service';
      _initialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signInWithEmailAndPassword(email, password);
      
      if (user != null) {
        _currentUser = user;
        await _setupUserNotifications(user);
        _errorMessage = null;
      } else {
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      print('Sign in error: $e');
      _errorMessage = 'Login failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Google Sign-In method
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        await _setupUserNotifications(user);
        _errorMessage = null;
      } else {
        _errorMessage = 'Google Sign-In failed';
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      _errorMessage = 'Google Sign-In failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required ModelUser.UserRole role,
    String? hospitalId,
    List<String>? associatedClinicIds, // New parameter for multiple clinic associations
    String? department,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await AuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        hospitalId: hospitalId,
        associatedClinicIds: associatedClinicIds,
        department: department,
        phone: phone,
      );
      
      if (user != null) {
        _currentUser = user;
        await _setupUserNotifications(user);
        _errorMessage = null;
      } else {
        _errorMessage = 'Registration failed';
      }
    } catch (e) {
      print('Sign up error: $e');
      String errorMsg = e.toString();
      
      // Extract meaningful error message from DioException
      if (errorMsg.contains('Email already registered')) {
        _errorMessage = '📧 Email already registered! Please login or use a different email.';
      } else if (errorMsg.contains('403')) {
        _errorMessage = '⚠️ Phone number already registered. Please login instead.';
      } else if (errorMsg.contains('400')) {
        // Extract backend error message
        if (errorMsg.contains('Exception:')) {
          _errorMessage = errorMsg.replaceAll('Exception:', '').trim();
        } else {
          _errorMessage = '❌ Invalid details. Please check your information.';
        }
      } else if (errorMsg.contains('Connection refused') || errorMsg.contains('SocketException')) {
        _errorMessage = '🌐 Network error. Please check your internet connection.';
      } else {
        _errorMessage = '❌ ${errorMsg.replaceAll("Exception: ", "")}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> forceLogout() async {
    await AuthService.resetAuthData();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }


  Future<void> signOut() async {
    try {
      // Cleanup notifications before signing out
      if (_currentUser != null) {
        await _cleanupUserNotifications(_currentUser!);
      }
      
      await AuthService.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      print('Error during sign out: $e');
      // Still clear local state even if backend call fails
      _currentUser = null;
      _errorMessage = null;
      await AuthService.resetAuthData(); // Ensure auth data is cleared
      notifyListeners();
    }
  }

  Future<void> _setupUserNotifications(ModelUser.User user) async {
    try {
      // Just call the initialize method for now
      await NotificationService.initialize();
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }

  Future<void> _cleanupUserNotifications(ModelUser.User user) async {
    try {
      // No cleanup needed for now
    } catch (e) {
      print('Error cleaning up notifications: $e');
    }
  }

  Future<void> _refreshUserData() async {
    try {
      if (await AuthService.isTokenValid()) {
        _currentUser = AuthService.currentUser;
        notifyListeners();
      } else {
        // If token is no longer valid, sign out
        await signOut();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      // If refresh fails, sign out
      await signOut();
    }
  }

  Future<void> requestOTP(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.requestOTP(phone);
      
      if (response['success'] == true || response['message'] != null) {
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to send OTP';
      }
    } catch (e) {
      print('Request OTP error: $e');
      _errorMessage = 'Failed to send OTP: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOTP(String identifier, String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Determine if identifier is email or phone
      bool isEmail = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(identifier);
      Map<String, dynamic> response;
      
      if (isEmail) {
        response = await AuthService.verifyOTP(identifier, otpCode);
      } else {
        response = await AuthService.verifyPhoneOTP(identifier, otpCode);
      }
      
      print('OTP Verification Response: $response');
      
      if (response['access_token'] != null) {
        // Existing user - Login successful
        // Extract user data from response if available
        if (response.containsKey('user') && response['user'] != null) {
          _currentUser = ModelUser.User.fromMap(response['user']);
          
          // Save auth data using AuthService internal method via initialization
          await AuthService.initialize();
          
          await _setupUserNotifications(_currentUser!);
          _errorMessage = null;
          print('✅ Login successful for existing user');
        } else {
          // User data not in response, try to fetch profile
          try {
            final userProfile = await AuthService.getProfile();
            _currentUser = ModelUser.User.fromMap(userProfile);
            await AuthService.initialize();
            
            await _setupUserNotifications(_currentUser!);
            _errorMessage = null;
            print('✅ Login successful - fetched profile separately');
          } catch (e) {
            _errorMessage = 'Failed to load user profile';
            print('❌ Error getting profile after OTP success: $e');
          }
        }
      } else if (response.containsKey('detail') || response.containsKey('message')) {
        // Backend returned an error message
        _errorMessage = response['detail'] ?? response['message'] ?? 'Verification failed';
        print('❌ Verification failed: $_errorMessage');
      } else {
        // This shouldn't happen now as backend returns error for new users
        _errorMessage = 'Invalid OTP or verification failed';
        print('❌ Verification failed');
      }
    } catch (e) {
      print('Verify OTP error: $e');
      // Extract meaningful error message
      String errorMsg = e.toString();
      
      // Check for specific backend error messages
      if (errorMsg.contains('Phone number not registered') || 
          errorMsg.contains('not registered')) {
        _errorMessage = 'Phone number not registered. Please create an account first.';
      } else if (errorMsg.contains('Invalid OTP')) {
        _errorMessage = 'Invalid OTP code. Please try again.';
      } else if (errorMsg.contains('Too many failed attempts')) {
        _errorMessage = 'Too many failed attempts. Please request a new OTP.';
      } else if (errorMsg.contains('403')) {
        // Backend returned 403 Forbidden
        _errorMessage = 'Phone number not registered. Please sign up first.';
      } else if (errorMsg.contains('400')) {
        // Bad request - extract actual message if available
        if (errorMsg.contains('Exception:')) {
          _errorMessage = errorMsg.replaceAll('Exception:', '').trim();
        } else {
          _errorMessage = 'Verification failed. Please check your OTP and try again.';
        }
      } else {
        _errorMessage = 'Verification failed: ${e.toString()}';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}