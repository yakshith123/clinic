import 'package:dio/dio.dart';
import 'auth_service.dart';
import '../models/qr_registration.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QrService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static final Dio _dio = Dio();
  static bool _initialized = false;
  
  // Firebase configuration for direct REST API calls
  static const String _firebaseProjectId = 'patient-qr-registration';
  static const String _firebaseApiKey = 'AIzaSyD9h9Y_1_QmUHpJHK-66dtvUG6l5eUIa98';

  static Future<void> initialize() async {
    if (_initialized) return; // Skip if already initialized
    
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10), // Reduced from 30s to 10s
      receiveTimeout: const Duration(seconds: 10), // Reduced from 30s to 10s
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _initialized = true;
    print('✅ QR Service initialized with base URL: $_baseUrl');
  }

  static Future<List<QrRegistration>> getQrRegistrations({String? clinicId}) async {
    try {
      print('📥 Fetching patient registrations for clinic: $clinicId');
      
      // Use backend Firebase proxy endpoint
      final authHeaders = AuthService.getAuthHeaders();
      
      if (clinicId != null && clinicId.isNotEmpty) {
        final response = await _dio.get(
          '/appointments/firebase/patients/$clinicId',
          options: Options(headers: authHeaders),
        );
        
        if (response.data != null && response.data is List) {
          final List<dynamic> data = response.data;
          print('✅ Loaded ${data.length} patient registrations from Firebase via backend');
          
          return data.map((item) {
            return QrRegistration.fromMap({
              'id': item['id'] ?? '',
              'fullName': item['fullName'] ?? 'Unknown',
              'mobileNumber': item['mobileNumber'] ?? '',
              'email': item['email'] ?? '',
              'hospitalId': item['hospitalId'] ?? '',
              'hospitalName': item['hospitalName'] ?? '',
              'visitType': item['visitType'] ?? 'Consultation',
              'symptoms': item['symptoms'] ?? '',
              'status': item['status'] ?? 'registered',
              'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
            });
          }).toList();
        }
      }
      
      print('⚠️ No patient data available for clinic: $clinicId');
      return [];
      
    } on Exception catch (e) {
      print('❌ Error fetching patient registrations: $e');
      rethrow;
    }
  }

  static Future<List<QrRegistration>> getMrRegistrations({String? clinicId}) async {
    try {
      // Ensure service is initialized
      await initialize();
      
      print('📥 Fetching MR registrations for clinic: $clinicId');
      
      // Use backend Firebase proxy endpoint
      final authHeaders = AuthService.getAuthHeaders();
      print('🔐 Auth headers: ${authHeaders.isNotEmpty ? "Present" : "Missing"}');
      print('🔑 Auth token present: ${AuthService.authToken != null}');
      
      if (clinicId != null && clinicId.isNotEmpty) {
        print('🌐 Making API call to: /appointments/firebase/mr/$clinicId');
        print('📡 Base URL: $_baseUrl');
        
        final response = await _dio.get(
          '/appointments/firebase/mr/$clinicId',
          options: Options(headers: authHeaders),
        );
        
        print('📊 Response status: ${response.statusCode}');
        print('📊 Response data type: ${response.data.runtimeType}');
        
        if (response.data != null && response.data is List) {
          final List<dynamic> data = response.data;
          print('✅ Loaded ${data.length} MR registrations from Firebase via backend');
          
          if (data.isEmpty) {
            print('⚠️ No MR appointments found for this clinic');
          }
          
          return data.map((item) {
            return QrRegistration.fromMap({
              'id': item['id'] ?? '',
              'fullName': item['fullName'] ?? 'Unknown MR',
              'mobileNumber': item['mobileNumber'] ?? '',
              'email': item['email'] ?? '',
              'hospitalId': item['hospitalId'] ?? '',
              'hospitalName': item['hospitalName'] ?? '',
              'visitType': item['visitType'] ?? 'Information Sharing',
              'symptoms': item['symptoms'] ?? 'General',
              'status': item['status'] ?? 'pending',
              'createdAt': item['createdAt'] ?? DateTime.now().toIso8601String(),
            });
          }).toList();
        } else {
          print('⚠️ Unexpected response format: ${response.data}');
          print('⚠️ Full response: ${response.data}');
        }
      } else {
        print('⚠️ No clinic ID provided');
      }
      
      print('⚠️ Returning empty MR list');
      return [];
      
    } on DioException catch (e) {
      print('❌ DioError fetching MR: ${e.message}');
      print('❌ Error type: ${e.type}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Error response headers: ${e.response?.headers}');
      return [];
    } catch (e) {
      print('❌ Error fetching MR registrations: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<List<QrRegistration>> getQrRegistrationsByHospital(String hospitalId) async {
    try {
      final authHeaders = AuthService.getAuthHeaders();
      final response = await _dio.get<List>(
        '/hospital/$hospitalId',
        options: Options(headers: authHeaders),
      );
      
      final List<dynamic> data = response.data ?? [];
      return data.map((item) => QrRegistration.fromMap(item)).toList();
    } on DioException catch (e) {
      print('Error fetching QR registrations by hospital: $e');
      rethrow;
    }
  }

  static Future<List<QrRegistration>> getQrRegistrationsByStatus(String status) async {
    try {
      final authHeaders = AuthService.getAuthHeaders();
      final response = await _dio.get<List>(
        '/status/$status',
        options: Options(headers: authHeaders),
      );
      
      final List<dynamic> data = response.data ?? [];
      return data.map((item) => QrRegistration.fromMap(item)).toList();
    } on DioException catch (e) {
      print('Error fetching QR registrations by status: $e');
      rethrow;
    }
  }
}