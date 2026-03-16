import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  static final Dio _dio = Dio();
  static BuildContext? _context;
  
  static bool _isInitialized = false;
  static int _retryCount = 0;
  static const int _maxRetries = 3;

  static void setNavigationContext(BuildContext context) {
    _context = context;
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Add persistent connection to reuse connections
      persistentConnection: true,
    );
    
    // Add interceptors for logging and error handling
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
        requestHeader: false,
        responseHeader: false,
      ));
    }
    
    // Add error interceptor for authentication
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, ErrorInterceptorHandler handler) {
        if (error.response?.statusCode == 401) {
          print('⚠️ 401 Unauthorized - Token may have expired');
          // Clear auth data
          AuthService.resetAuthData();
          
          // Navigate to login screen
          if (_context != null) {
            // Find the navigator state and push replacement
            Navigator.of(_context!, rootNavigator: true).pushNamedAndRemoveUntil(
              '/login',
              (route) => false, // Remove all routes from stack
            );
          }
        }
        handler.next(error);
      },
    ));
    
    _isInitialized = true;
    print('API Service initialized with base URL: $_baseUrl');
  }

  // HTTP Methods with retry logic
  static Future<Response<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get<T>(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      _retryCount = 0; // Reset on success
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _retryCount < _maxRetries) {
        _retryCount++;
        print('🔄 Connection error - Retry $_retryCount/$_maxRetries for $endpoint');
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
        return get<T>(endpoint, queryParameters: queryParameters, headers: headers);
      }
      _retryCount = 0;
      _handleDioError(e);
      rethrow;
    }
  }

  static Future<Response<T>> post<T>(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post<T>(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );
      _retryCount = 0; // Reset on success
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError && _retryCount < _maxRetries) {
        _retryCount++;
        print('🔄 Connection error - Retry $_retryCount/$_maxRetries for $endpoint');
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
        return post<T>(endpoint, data, headers: headers);
      }
      _retryCount = 0;
      _handleDioError(e);
      rethrow;
    }
  }

  static Future<Response<T>> put<T>(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put<T>(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  static Future<Response<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete<T>(
        endpoint,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  static void _handleDioError(DioException error) {
    // Silently handle connection errors during retries
    if (error.type == DioExceptionType.connectionError) {
      print('⚠️ Network error: ${error.message}');
      return;
    }
    
    String errorMessage = 'Network error occurred';
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _parseErrorResponse(error.response?.statusCode, error.response?.data);
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown network error. Please try again.';
        break;
      default:
        errorMessage = 'An error occurred. Please try again.';
    }
    
    print('API Error: $errorMessage');
  }

  static String _parseErrorResponse(int? statusCode, dynamic data) {
    // Try to extract the actual error message from the response
    if (data != null) {
      try {
        if (data is Map<String, dynamic>) {
          // Check if the response contains a detail field with the error message
          if (data.containsKey('detail')) {
            final detail = data['detail'];
            if (detail is String) {
              return detail; // Return the actual error message
            } else if (detail is List) {
              // If detail is a list of validation errors, join them
              return detail.map((err) => err.toString()).join('; ');
            }
          }
          // If detail field doesn't exist, try other common fields
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
          if (data.containsKey('error')) {
            return data['error'].toString();
          }
        }
        // If it's not a Map, convert to string
        return data.toString();
      } catch (e) {
        // If parsing fails, fall back to status code based message
        print('Error parsing response: $e');
      }
    }
    
    // Default messages based on status code
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'Conflict. Data already exists.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed with status code: $statusCode';
    }
  }

  // Auth methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Send as form data for OAuth2PasswordRequestForm
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'username': email,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return response.data!;
  }

  static Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    final response = await post('/auth/register', userData);  // Correct endpoint
    return response.data as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    await post('/auth/logout', {});
  }

  // Forgot Password Methods
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await post('/auth/forgot-password', {'email': email});
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyOTP(String email, String otpCode) async {
    final response = await post('/auth/verify-otp', {
      'email': email,
      'otp_code': otpCode,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> requestOTP(String phone) async {
    final response = await post('/auth/request-phone-otp', {
      'phone': phone,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> verifyPhoneOTP(String phone, String otpCode) async {
    final response = await post('/auth/verify-phone-otp', {
      'phone': phone,
      'otp_code': otpCode,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String otpCode, String newPassword) async {
    final response = await post('/auth/reset-password', {
      'email': email,
      'otp_code': otpCode,
      'new_password': newPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/auth/me', headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }

  // User methods
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/users/$userId', headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/users/role/$role', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }
  
  // Get all users
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/users', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  // Doctor methods - reverted to original endpoint
  static Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/doctors', headers: authHeaders);  // Reverted to original endpoint
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  // Appointment methods
  static Future<List<Map<String, dynamic>>> getAppointmentsByDoctor(String doctorId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/appointments/doctor/$doctorId', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  static Future<List<Map<String, dynamic>>> getAppointmentsByPatient(String patientId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/appointments/patient/$patientId', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> appointmentData) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await post('/appointments', appointmentData, headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    final authHeaders = AuthService.getAuthHeaders();
    await put('/appointments/$appointmentId/status', {'status': status}, headers: authHeaders);
  }

  static Future<void> updateAppointmentPosition(String appointmentId, int position) async {
    final authHeaders = AuthService.getAuthHeaders();
    await put('/appointments/$appointmentId/position', {'position': position}, headers: authHeaders);
  }

  // Resource methods
  static Future<List<Map<String, dynamic>>> getResourcesByDoctor(String doctorId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/resources/doctor/$doctorId', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  static Future<List<Map<String, dynamic>>> getResourcesByClinic(String hospitalId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/resources/hospital/$hospitalId', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }

  static Future<Map<String, dynamic>> createResource(Map<String, dynamic> resourceData) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await post('/resources', resourceData, headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }

  // Hospital methods
  static Future<Map<String, dynamic>> getClinicById(String hospitalId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/clinics/$hospitalId', headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAllClinics() async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/clinics', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }
  
  // Add update hospital method
  static Future<Map<String, dynamic>> updateClinic(String hospitalId, Map<String, dynamic> hospitalData) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await put('/clinics/$hospitalId', hospitalData, headers: authHeaders);
    return response.data as Map<String, dynamic>;
  }
  
  // Add delete hospital method
  static Future<void> deleteClinic(String hospitalId) async {
    final authHeaders = AuthService.getAuthHeaders();
    await delete('/clinics/$hospitalId', headers: authHeaders);
  }
  
  // Add update user profile method
  static Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> userData) async {
    // Mock implementation since backend doesn't have user update endpoint
    // In a real app, you would call the backend endpoint
    print('Update user profile called with: $userData');
    // Return the user data as if it was updated
    return userData;
  }
  
  // Add method to get users by hospital
  static Future<List<Map<String, dynamic>>> getUsersByClinic(String hospitalId) async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/clinics/$hospitalId/users', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }
  
  // Add method to get hospitals by user
  static Future<List<Map<String, dynamic>>> getClinicsByUser() async {
    final authHeaders = AuthService.getAuthHeaders();
    final response = await get('/clinics/user', headers: authHeaders);
    return List<Map<String, dynamic>>.from(response.data as List);
  }
}