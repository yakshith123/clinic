import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as ModelUser;
import '../models/appointment.dart';
import '../models/clinic.dart';
import '../models/resource.dart';
import '../constants/app_constants.dart';

class LocalStorageService {
  static bool _isInitialized = false;
  static SharedPreferences? _prefs;

  // Initialize local storage
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('Local storage initialized - no external backend services');
  }

  // Helper to hash passwords
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Auth Methods
  static Future<ModelUser.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      final hashedPassword = _hashPassword(password);
      
      // Look for user in local storage
      final keys = _prefs!.getKeys();
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userJson = _prefs!.getString(key);
          if (userJson != null) {
            try {
              final userData = Map<String, dynamic>.from(jsonDecode(userJson));
              if (userData['email'] != null && 
                  userData['email'].toString().toLowerCase() == email.toLowerCase() && 
                  userData['password'] == hashedPassword) {
                return ModelUser.User.fromMap(userData);
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  static Future<ModelUser.User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    ModelUser.UserRole role,
    {String? hospitalId, String? department, String? phone}
  ) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      // Check if user already exists
      final keys = _prefs!.getKeys();
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userJson = _prefs!.getString(key);
          if (userJson != null) {
            try {
              final userData = Map<String, dynamic>.from(jsonDecode(userJson));
              if (userData['email'] != null && 
                  userData['email'].toString().toLowerCase() == email.toLowerCase()) {
                throw Exception('User with this email already exists');
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      final hashedPassword = _hashPassword(password);
      final userId = const Uuid().v4();
      
      final user = ModelUser.User(
        id: userId,
        email: email,
        name: name,
        phone: phone ?? '+1234567890',
        role: role,
        hospitalId: hospitalId,
        department: department,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Store in local storage
      await _prefs!.setString('user_$userId', jsonEncode({
        ...user.toMap(),
        'password': hashedPassword,
      }));
      
      return user;
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  static Future<void> signOut() async {
    // No session management needed
    print('User signed out');
  }

  static Stream<ModelUser.User?> authStateChanges() {
    // For local storage, we don't have built-in auth state changes
    return Stream.value(null);
  }

  // User Methods
  static Future<ModelUser.User?> getUserById(String userId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      final userDataJson = _prefs!.getString('user_$userId');
      if (userDataJson != null) {
        final userData = Map<String, dynamic>.from(jsonDecode(userDataJson));
        return ModelUser.User.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  static Future<List<ModelUser.User>> getUsersByRole(ModelUser.UserRole role) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      final users = <ModelUser.User>[];
      final roleName = role.toString().split('.').last;
      
      final keys = _prefs!.getKeys();
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userJson = _prefs!.getString(key);
          if (userJson != null) {
            try {
              final user = Map<String, dynamic>.from(jsonDecode(userJson));
              if (user['role'] == roleName) {
                users.add(ModelUser.User.fromMap(user));
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      return users;
    } catch (e) {
      print('Error getting users by role: $e');
      throw Exception('Failed to get users by role: $e');
    }
  }

  static Future<List<ModelUser.User>> getUsersByClinic(String hospitalId) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      
      final users = <ModelUser.User>[];
      
      final keys = _prefs!.getKeys();
      for (String key in keys) {
        if (key.startsWith('user_')) {
          final userJson = _prefs!.getString(key);
          if (userJson != null) {
            try {
              final user = Map<String, dynamic>.from(jsonDecode(userJson));
              if (user['hospitalId'] == hospitalId) {
                users.add(ModelUser.User.fromMap(user));
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
      
      return users;
    } catch (e) {
      print('Error getting users by hospital: $e');
      throw Exception('Failed to get users by hospital: $e');
    }
  }

  // Appointment Methods - Local Simulation
  static Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting appointments by patient: $e');
      throw Exception('Failed to get appointments by patient: $e');
    }
  }

  static Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting appointments by doctor: $e');
      throw Exception('Failed to get appointments by doctor: $e');
    }
  }

  static Future<List<Appointment>> getAppointmentsByClinic(String hospitalId) async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting appointments by hospital: $e');
      throw Exception('Failed to get appointments by hospital: $e');
    }
  }

  static Future<Appointment> createAppointment({
    required String patientId,
    required String doctorId,
    required String hospitalId,
    required DateTime appointmentDate,
    required String timeSlot,
    required String department,
    required String reason,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final appointmentId = const Uuid().v4();
      
      final appointment = Appointment(
        id: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        department: department,
        reason: reason,
        status: AppointmentStatus.pending,
        queuePosition: 0,
        patientLatitude: latitude,
        patientLongitude: longitude,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // For local simulation, just return the appointment
      return appointment;
    } catch (e) {
      print('Error creating appointment: $e');
      throw Exception('Failed to create appointment: $e');
    }
  }

  static Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    try {
      // Local simulation - just log the update
      print('Updated appointment $appointmentId status to ${status.toString()}');
    } catch (e) {
      print('Error updating appointment status: $e');
      throw Exception('Failed to update appointment status: $e');
    }
  }

  static Future<void> updateAppointmentQueuePosition(String appointmentId, int position) async {
    try {
      // Local simulation - just log the update
      print('Updated appointment $appointmentId queue position to $position');
    } catch (e) {
      print('Error updating appointment queue position: $e');
      throw Exception('Failed to update appointment queue position: $e');
    }
  }

  // Clinic Methods - Local Simulation
  static Future<Clinic?> getClinicById(String hospitalId) async {
    try {
      // Return null - local simulation only
      return null;
    } catch (e) {
      print('Error getting hospital: $e');
      throw Exception('Failed to get hospital: $e');
    }
  }

  static Future<List<Clinic>> getAllClinics() async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting hospitals: $e');
      throw Exception('Failed to get hospitals: $e');
    }
  }

  static Future<Clinic> createClinic({
    required String name,
    required String address,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required double latitude,
    required double longitude,
    required String phone,
    required String email,
    required List<String> departments,
  }) async {
    try {
      final hospitalId = const Uuid().v4();
      
      final hospital = Clinic(
        id: hospitalId,
        name: name,
        address: address,
        city: city,
        state: state,
        country: country,
        postalCode: postalCode,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        email: email,
        departments: departments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // For local simulation, just return the hospital
      return hospital;
    } catch (e) {
      print('Error creating hospital: $e');
      throw Exception('Failed to create hospital: $e');
    }
  }

  // Resource Methods - Local Simulation
  static Future<List<Resource>> getResourcesByDoctor(String doctorId) async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting resources by doctor: $e');
      throw Exception('Failed to get resources by doctor: $e');
    }
  }

  static Future<List<Resource>> getResourcesByClinic(String hospitalId) async {
    try {
      // Return empty list - local simulation only
      return [];
    } catch (e) {
      print('Error getting resources by hospital: $e');
      throw Exception('Failed to get resources by hospital: $e');
    }
  }

  static Future<Resource> createResource({
    required String name,
    required String company,
    required String contactPerson,
    required String contactPhone,
    required String contactEmail,
    required ResourceType type,
    required String doctorId,
    required String hospitalId,
    required DateTime scheduledDate,
    required String timeSlot,
  }) async {
    try {
      final resourceId = const Uuid().v4();
      
      final resource = Resource(
        id: resourceId,
        name: name,
        company: company,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        type: type,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // For local simulation, just return the resource
      return resource;
    } catch (e) {
      print('Error creating resource: $e');
      throw Exception('Failed to create resource: $e');
    }
  }

  // Close connection
  static Future<void> closeConnection() async {
    _isInitialized = false;
    print('Local storage connection closed - no external backend services');
  }
}