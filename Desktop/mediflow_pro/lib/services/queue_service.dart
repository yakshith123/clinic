import '../models/appointment.dart';
import '../models/resource.dart';
import '../models/clinic.dart';
import '../models/user.dart' as ModelUser;
import 'api_service.dart';
import 'auth_service.dart';

class QueueService {
  static Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    try {
      final appointmentsData = await ApiService.getAppointmentsByDoctor(doctorId);
      return appointmentsData
          .map((data) => Appointment.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting appointments by doctor: $e');
      rethrow;
    }
  }

  static Future<List<Appointment>> getAppointmentsByPatient(String patientId) async {
    try {
      final appointmentsData = await ApiService.getAppointmentsByPatient(patientId);
      return appointmentsData
          .map((data) => Appointment.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting appointments by patient: $e');
      rethrow;
    }
  }

  static Future<List<Appointment>> getAppointmentsByClinic(String hospitalId) async {
    try {
      final response = await ApiService.get(
        '/appointments/hospital/$hospitalId',
        headers: AuthService.getAuthHeaders(),
      );
      final appointmentsData = response.data as List;
      return appointmentsData
          .map((data) => Appointment.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting appointments by hospital: $e');
      rethrow;
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
      final appointmentData = {
        'patient_id': patientId,
        'doctor_id': doctorId,
        'hospital_id': hospitalId,
        'appointment_date': appointmentDate.toIso8601String(),
        'time_slot': timeSlot,
        'department': department,
        'reason': reason,
        'patient_latitude': latitude,
        'patient_longitude': longitude,
      };

      final response = await ApiService.createAppointment(appointmentData);
      return Appointment.fromMap(response);
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  static Future<void> updateAppointmentStatus(
    String appointmentId, 
    AppointmentStatus status
  ) async {
    try {
      await ApiService.updateAppointmentStatus(
        appointmentId, 
        status.toString().split('.').last
      );
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }

  static Future<void> updateAppointmentQueuePosition(
    String appointmentId, 
    int position
  ) async {
    try {
      await ApiService.updateAppointmentPosition(appointmentId, position);
    } catch (e) {
      print('Error updating appointment queue position: $e');
      rethrow;
    }
  }

  // Resource methods
  static Future<List<Resource>> getResourcesByDoctor(String doctorId) async {
    try {
      final resourcesData = await ApiService.getResourcesByDoctor(doctorId);
      return resourcesData
          .map((data) => Resource.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting resources by doctor: $e');
      rethrow;
    }
  }

  static Future<List<Resource>> getResourcesByClinic(String hospitalId) async {
    try {
      final resourcesData = await ApiService.getResourcesByClinic(hospitalId);
      return resourcesData
          .map((data) => Resource.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting resources by hospital: $e');
      rethrow;
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
      final resourceData = {
        'name': name,
        'company': company,
        'contact_person': contactPerson,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'type': type.toString().split('.').last,
        'doctor_id': doctorId,
        'hospital_id': hospitalId,
        'scheduled_date': scheduledDate.toIso8601String(),
        'time_slot': timeSlot,
      };

      final response = await ApiService.createResource(resourceData);
      return Resource.fromMap(response);
    } catch (e) {
      print('Error creating resource: $e');
      rethrow;
    }
  }

  // Clinic methods
  static Future<Clinic?> getClinicById(String hospitalId) async {
    try {
      final hospitalData = await ApiService.getClinicById(hospitalId);
      return Clinic.fromMap(hospitalData);
    } catch (e) {
      print('Error getting hospital: $e');
      return null;
    }
  }

  static Future<List<Clinic>> getAllClinics() async {
    try {
      final hospitalsData = await ApiService.getAllClinics();
      return hospitalsData
          .map((data) => Clinic.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting hospitals: $e');
      // Return demo hospitals if API fails
      final now = DateTime.now();
      return [
        Clinic(
          id: 'hospital_1',
          name: 'Devasya Superspeciality Kidney + Multispeciality',
          address: 'Mumbai',
          city: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          postalCode: '400001',
          latitude: 19.0760,
          longitude: 72.8777,
          phone: '+91-22-12345678',
          email: 'info@devasyahospital.com',
          departments: ['Kidney', 'Multispeciality'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_2',
          name: 'Tata Memorial',
          address: 'Parel',
          city: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          postalCode: '400012',
          latitude: 18.9892,
          longitude: 72.8330,
          phone: '+91-22-24146000',
          email: 'info@tmc.gov.in',
          departments: ['Oncology', 'Cancer Treatment'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_3',
          name: 'Max Super Speciality',
          address: 'Saket',
          city: 'New Delhi',
          state: 'Delhi',
          country: 'India',
          postalCode: '110017',
          latitude: 28.5245,
          longitude: 77.2030,
          phone: '+91-11-26515151',
          email: 'info@maxhealthcare.in',
          departments: ['Cardiology', 'Orthopedics', 'Neurology'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_4',
          name: 'Kokilaben Dhirubhai Ambani',
          address: 'Andheri West',
          city: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          postalCode: '400053',
          latitude: 19.1818,
          longitude: 72.8397,
          phone: '+91-22-30999999',
          email: 'feedback@kokilaben.com',
          departments: ['Cardiology', 'IVF', 'Oncology'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_5',
          name: 'Aditya Birla Memorial',
          address: 'Pune',
          city: 'Pune',
          state: 'Maharashtra',
          country: 'India',
          postalCode: '411057',
          latitude: 18.5204,
          longitude: 73.8567,
          phone: '+91-20-67002020',
          email: 'info@adityabirlahospital.com',
          departments: ['Cardiology', 'Orthopedics', 'Neurology'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_6',
          name: 'Aster CMI',
          address: 'Bengaluru',
          city: 'Bangalore',
          state: 'Karnataka',
          country: 'India',
          postalCode: '560076',
          latitude: 12.9716,
          longitude: 77.5946,
          phone: '+91-80-49664966',
          email: 'astercmihospital@asterhospitals.com',
          departments: ['Cardiology', 'Orthopedics', 'Neurology'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_7',
          name: 'Manipal',
          address: 'Old Airport Road',
          city: 'Bangalore',
          state: 'Karnataka',
          country: 'India',
          postalCode: '560017',
          latitude: 12.9716,
          longitude: 77.5946,
          phone: '+91-80-25024444',
          email: 'bangalore@manipal.edu',
          departments: ['Cardiology', 'Oncology', 'Orthopedics'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_8',
          name: 'Koshys',
          address: 'Whitefield',
          city: 'Bangalore',
          state: 'Karnataka',
          country: 'India',
          postalCode: '560066',
          latitude: 12.9716,
          longitude: 77.5946,
          phone: '+91-80-25024444',
          email: 'info@koshys.com',
          departments: ['General Medicine', 'Pediatrics'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_9',
          name: 'Motherhood',
          address: 'Sector 14',
          city: 'Gurgaon',
          state: 'Haryana',
          country: 'India',
          postalCode: '122001',
          latitude: 28.4595,
          longitude: 77.0266,
          phone: '+91-124-4678000',
          email: 'info@motherhoodhospitals.com',
          departments: ['Obstetrics', 'Gynecology', 'Pediatrics'],
          createdAt: now,
          updatedAt: now,
        ),
        Clinic(
          id: 'hospital_10',
          name: 'Apollo Cradle & Children\'s',
          address: 'Gachibowli',
          city: 'Hyderabad',
          state: 'Telangana',
          country: 'India',
          postalCode: '500032',
          latitude: 17.4411,
          longitude: 78.3915,
          phone: '+91-40-29804000',
          email: 'info@apollohospitals.com',
          departments: ['Pediatrics', 'Obstetrics', 'Neonatology'],
          createdAt: now,
          updatedAt: now,
        ),
      ];
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
      final hospitalData = {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': email,
        'departments': departments,
      };

      final response = await ApiService.post(
        '/hospitals/',
        hospitalData,
        headers: AuthService.getAuthHeaders(),
      );
      return Clinic.fromMap(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error creating hospital: $e');
      rethrow;
    }
  }
  
  // Add update hospital method
  static Future<Clinic> updateClinic(String hospitalId, {
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
      final hospitalData = {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': email,
        'departments': departments,
      };

      final response = await ApiService.updateClinic(hospitalId, hospitalData);
      return Clinic.fromMap(response);
    } catch (e) {
      print('Error updating hospital: $e');
      rethrow;
    }
  }
  
  // Add delete hospital method
  static Future<void> deleteClinic(String hospitalId) async {
    try {
      await ApiService.deleteClinic(hospitalId);
    } catch (e) {
      print('Error deleting hospital: $e');
      rethrow;
    }
  }
  
  // Add a method to get hospitals by user
  static Future<List<Clinic>> getClinicsByUser() async {
    try {
      final response = await ApiService.get('/hospitals/user');
      final List<dynamic> hospitalsData = response.data as List<dynamic>;
      return hospitalsData
          .map((data) => Clinic.fromMap(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting hospitals by user: $e');
      // Return empty list if API fails
      return [];
    }
  }
  
  // Add update user profile method
  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? phone,
    String? email,
  }) async {
    try {
      final profileData = <String, dynamic>{};
      if (name != null) profileData['name'] = name;
      if (phone != null) profileData['phone'] = phone;
      if (email != null) profileData['email'] = email;

      final response = await ApiService.updateUserProfile(profileData);
      return response;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
  
  // User methods
  static Future<List<ModelUser.User>> getAllDoctors() async {
    try {
      final doctorsData = await ApiService.getAllDoctors();
      return doctorsData
          .map((data) => ModelUser.User.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting all doctors: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      final usersData = await ApiService.getUsersByRole(role);
      return usersData;
    } catch (e) {
      print('Error getting users by role: $e');
      rethrow;
    }
  }
  
  // Add a method to get users by hospital if needed

  static Future<List<ModelUser.User>> getUsersByClinic(String clinicId) async {
    try {
      final usersData = await ApiService.getUsersByClinic(clinicId);
      return usersData
          .map((data) => ModelUser.User.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting users by clinic: $e');
      return [];
    }
  }
}
