import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/appointment.dart';
import '../models/resource.dart';
import '../models/clinic.dart';
import '../services/queue_service.dart';

class QueueProvider with ChangeNotifier {
  List<Appointment> _patientQueue = [];
  List<Appointment> _allPatientQueue = []; // Keep all appointments for reference
  List<Resource> _resourceQueue = [];
  Clinic? _currentClinic;
  String? _errorMessage;
  bool _isSessionActive = false;
  String _currentDoctorId = '';
  String _currentClinicId = '';

  List<Appointment> get patientQueue => _patientQueue;
  List<Resource> get resourceQueue => _resourceQueue;
  Clinic? get currentClinic => _currentClinic;
  String? get errorMessage => _errorMessage;
  bool get isSessionActive => _isSessionActive;
  int get totalQueueCount => _patientQueue.length;
  
  // Filtered queues - exclude completed and cancelled appointments from active lists
  List<Appointment> get activePatientQueue => _patientQueue.where((appointment) => 
      appointment.status != AppointmentStatus.completed && 
      appointment.status != AppointmentStatus.cancelled
  ).toList();
  
  List<Appointment> get completedAppointments => _patientQueue.where((appointment) => 
      appointment.status == AppointmentStatus.completed
  ).toList();
  
  List<Appointment> get cancelledAppointments => _patientQueue.where((appointment) => 
      appointment.status == AppointmentStatus.cancelled
  ).toList();

  // Filtered queues based on current hospital
  List<Appointment> getActiveQueue(String hospitalId) {
    return activePatientQueue.where((appointment) => 
        appointment.hospitalId == hospitalId
    ).toList();
  }

  List<Appointment> getConsultantQueue(String hospitalId) {
    // For now, returning the same as active queue
    // In the future, this could filter for consultant-specific appointments
    return _patientQueue.where((appointment) => 
        appointment.hospitalId == hospitalId &&
        (appointment.status == AppointmentStatus.pending ||
         appointment.status == AppointmentStatus.confirmed ||
         appointment.status == AppointmentStatus.inProgress)
    ).toList();
  }

  int getWaitingCount(String hospitalId) {
    return activePatientQueue.where((appointment) => 
        appointment.hospitalId == hospitalId &&
        appointment.status == AppointmentStatus.confirmed
    ).length;
  }

  int getCompletedTodayCount(String hospitalId) {
    final today = DateTime.now();
    return completedAppointments.where((appointment) => 
        appointment.hospitalId == hospitalId &&
        appointment.updatedAt.day == today.day &&
        appointment.updatedAt.month == today.month &&
        appointment.updatedAt.year == today.year
    ).length;
  }

  int getAverageWaitTime(String hospitalId) {
    final activePatients = activePatientQueue.where((appointment) => 
        appointment.hospitalId == hospitalId &&
        appointment.status == AppointmentStatus.confirmed
    ).toList();

    if (activePatients.isEmpty) return 0;

    // Calculate average wait time in minutes
    int totalWaitTime = 0;
    for (var patient in activePatients) {
      final waitTime = DateTime.now().difference(patient.createdAt).inMinutes;
      totalWaitTime += waitTime;
    }

    return (totalWaitTime / activePatients.length).round();
  }

  Future<void> initializeQueue(String doctorId, String hospitalId) async {
    await refreshQueues(doctorId, hospitalId);
  }

  Future<void> refreshQueues(String doctorId, String hospitalId) async {
    try {
      _currentDoctorId = doctorId;
      _currentClinicId = hospitalId;
      
      print('🔄 Refreshing queues for doctor: $doctorId, clinic: $hospitalId');
      
      // Load appointments from backend if available
      final appointments = await QueueService.getAppointmentsByDoctor(doctorId);
      print('✅ Loaded ${appointments.length} appointments from backend');
      
      // Separate active and completed appointments
      List<Appointment> activeAppointments = [];
      List<Appointment> completedAppointments = [];
      
      for (var appointment in appointments) {
        if (appointment.status == AppointmentStatus.completed || 
            appointment.status == AppointmentStatus.cancelled) {
          completedAppointments.add(appointment);
        } else {
          activeAppointments.add(appointment);
        }
      }
      
      // Sort active appointments by creation time (as arrival time equivalent)
      activeAppointments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Update state
      _allPatientQueue = appointments;
      _patientQueue = activeAppointments;
      
      // Also load consultant queue if needed
      try {
        final consultantAppointments = await QueueService.getAppointmentsByClinic(hospitalId);
        _patientQueue.addAll(consultantAppointments.where((apt) => 
          apt.status != AppointmentStatus.completed && 
          apt.status != AppointmentStatus.cancelled
        ).toList());
        print('✅ Loaded consultant queue: ${consultantAppointments.length} appointments');
      } catch (e) {
        print('⚠️ Error loading consultant queue: $e');
        // Don't fail completely - just continue without consultant queue
      }
      
      // If backend returns NO data, load dummy data for demonstration
      if (_patientQueue.isEmpty) {
        print('⚠️ No appointments found in backend - loading demo data for testing');
        loadDummyData(doctorId, hospitalId);
      }
      
      notifyListeners();
      print('✅ Queues refreshed successfully - Total: ${_patientQueue.length}, Active: ${activePatientQueue.length}');
    } catch (e) {
      print('❌ Error refreshing queues: $e');
      _errorMessage = e.toString();
      // Fallback to dummy data if API fails
      print('⚠️ Loading fallback data...');
      loadDummyData(doctorId, hospitalId);
      notifyListeners();
    }
  }
  
  void loadDummyData(String doctorId, String hospitalId) {
    final now = DateTime.now();
    
    // Create dummy patient appointments
    _allPatientQueue = [
      // Pending appointments
      Appointment(
        id: 'pending_1',
        patientId: 'PAT001',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(hours: 1)),
        timeSlot: '10:00 AM',
        department: 'Cardiology',
        reason: 'Annual heart checkup and ECG',
        status: AppointmentStatus.pending,
        queuePosition: 1,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      Appointment(
        id: 'pending_2',
        patientId: 'PAT002',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(hours: 1, minutes: 30)),
        timeSlot: '10:30 AM',
        department: 'Orthopedics',
        reason: 'Knee pain consultation',
        status: AppointmentStatus.pending,
        queuePosition: 2,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now,
      ),
      
      // Confirmed appointments
      Appointment(
        id: 'confirmed_1',
        patientId: 'PAT003',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(minutes: 30)),
        timeSlot: '09:30 AM',
        department: 'General Medicine',
        reason: 'Fever and body aches',
        status: AppointmentStatus.confirmed,
        queuePosition: 1,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      Appointment(
        id: 'confirmed_2',
        patientId: 'PAT004',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(hours: 1)),
        timeSlot: '10:00 AM',
        department: 'Dermatology',
        reason: 'Skin rash consultation',
        status: AppointmentStatus.confirmed,
        queuePosition: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      Appointment(
        id: 'confirmed_3',
        patientId: 'PAT005',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(hours: 1, minutes: 30)),
        timeSlot: '10:30 AM',
        department: 'Neurology',
        reason: 'Headache and dizziness',
        status: AppointmentStatus.confirmed,
        queuePosition: 3,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
      
      // In-progress appointment
      Appointment(
        id: 'in_progress_1',
        patientId: 'PAT006',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.subtract(const Duration(minutes: 15)),
        timeSlot: '09:00 AM',
        department: 'Cardiology',
        reason: 'Emergency chest pain',
        status: AppointmentStatus.inProgress,
        queuePosition: 0,
        isEmergency: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now,
      ),
      
      // Completed appointments (from today)
      Appointment(
        id: 'completed_1',
        patientId: 'PAT007',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.subtract(const Duration(hours: 3)),
        timeSlot: '08:00 AM',
        department: 'General Medicine',
        reason: 'Routine blood work',
        status: AppointmentStatus.completed,
        queuePosition: 0,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      Appointment(
        id: 'completed_2',
        patientId: 'PAT008',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.subtract(const Duration(hours: 4)),
        timeSlot: '07:30 AM',
        department: 'Pediatrics',
        reason: 'Child vaccination',
        status: AppointmentStatus.completed,
        queuePosition: 0,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      
      // Cancelled appointment
      Appointment(
        id: 'cancelled_1',
        patientId: 'PAT009',
        doctorId: doctorId,
        hospitalId: hospitalId,
        appointmentDate: now.add(const Duration(hours: 2)),
        timeSlot: '11:00 AM',
        department: 'Ophthalmology',
        reason: 'Eye examination',
        status: AppointmentStatus.cancelled,
        queuePosition: 0,
        createdAt: now.subtract(const Duration(hours: 24)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
    
    // Filter appointments for the current hospital
    _patientQueue = _allPatientQueue.where((appointment) => 
        appointment.hospitalId == hospitalId
    ).toList();
    
    // Create dummy resources
    _resourceQueue = [
      // Equipment resources
      Resource(
        id: 'equip_1',
        name: 'MRI Scanner - Room 101',
        company: 'Siemens Healthineers',
        contactPerson: 'Dr. Sarah Johnson',
        contactPhone: '+1-555-0101',
        contactEmail: 's.johnson@hospital.com',
        type: ResourceType.equipment,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: now.add(const Duration(hours: 2)),
        timeSlot: '11:00 AM - 12:00 PM',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      Resource(
        id: 'equip_2',
        name: 'CT Scan Machine - Room 102',
        company: 'GE Healthcare',
        contactPerson: 'Dr. Michael Chen',
        contactPhone: '+1-555-0102',
        contactEmail: 'm.chen@hospital.com',
        type: ResourceType.equipment,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: now.add(const Duration(hours: 3)),
        timeSlot: '1:00 PM - 2:30 PM',
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now,
      ),
      
      // Consultant resources
      Resource(
        id: 'cons_1',
        name: 'Dr. Emily Rodriguez',
        company: 'City General Clinic',
        contactPerson: 'Dr. Emily Rodriguez',
        contactPhone: '+1-555-0201',
        contactEmail: 'e.rodriguez@hospital.com',
        type: ResourceType.staff,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: now.add(const Duration(hours: 1)),
        timeSlot: '10:00 AM - 11:00 AM',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now,
      ),
      Resource(
        id: 'cons_2',
        name: 'Dr. James Wilson',
        company: 'Medical Specialists Inc',
        contactPerson: 'Dr. James Wilson',
        contactPhone: '+1-555-0202',
        contactEmail: 'j.wilson@medspec.com',
        type: ResourceType.staff,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: now.add(const Duration(hours: 4)),
        timeSlot: '3:00 PM - 4:00 PM',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now,
      ),
      
      // Staff resources
      Resource(
        id: 'staff_1',
        name: 'Nurse Sarah Thompson',
        company: 'City General Clinic',
        contactPerson: 'Nurse Sarah Thompson',
        contactPhone: '+1-555-0301',
        contactEmail: 's.thompson@hospital.com',
        type: ResourceType.staff,
        doctorId: doctorId,
        hospitalId: hospitalId,
        scheduledDate: now.add(const Duration(minutes: 30)),
        timeSlot: '09:30 AM - 12:00 PM',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
      ),
    ];
    
    // Create dummy hospital
    _currentClinic = Clinic(
      id: hospitalId,
      name: 'City General Clinic',
      address: '123 Medical Drive',
      city: 'Healthville',
      state: 'CA',
      country: 'USA',
      postalCode: '12345',
      latitude: 37.7749,
      longitude: -122.4194,
      phone: '555-123-4567',
      email: 'info@cityhospital.com',
      departments: ['Cardiology', 'Orthopedics', 'Neurology'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> loadQueues(String doctorId, String hospitalId) async {
    await refreshQueues(doctorId, hospitalId);
  }

  Future<void> startSession([String? appointmentId]) async {
    try {
      _isSessionActive = true;
      // Send notifications to registered patients
      await sendSessionStartNotifications();
      notifyListeners();
    } catch (e) {
      print('Error starting session: $e');
      _errorMessage = 'Failed to start session: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> stopSession() async {
    try {
      _isSessionActive = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping session: $e');
      _errorMessage = 'Failed to stop session: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> sendSessionStartNotifications() async {
    try {
      // Send SMS notifications to first 5 patients in queue who registered via QR code
      final patientsToNotify = _patientQueue
          .where((appointment) => 
              appointment.status == AppointmentStatus.confirmed ||
              appointment.status == AppointmentStatus.pending)
          .take(5)
          .toList();
      
      for (var appointment in patientsToNotify) {
        // Send SMS notification to patient's phone number
        await _sendSMSNotification(appointment);
      }
      
      print('Sent session start SMS notifications to ${patientsToNotify.length} patients');
    } catch (e) {
      print('Error sending session start notifications: $e');
    }
  }
  
  Future<void> _sendSMSNotification(Appointment appointment) async {
    // In a real implementation, this would integrate with an SMS service like Twilio
    // For now, we'll simulate sending an SMS to the patient's phone number
    
    // Assuming the patient ID can be used to look up their phone number
    String phoneNumber = '+1-${appointment.patientId.substring(0, math.min(appointment.patientId.length, 10))}';
    String message = 'Dear Patient, your doctor\'s session has started. You are #${appointment.queuePosition} in queue. Please proceed to the clinic.';
    
    print('[SMS SENT] To: $phoneNumber - Message: $message');
    
    // Here you would integrate with an actual SMS service
    // Example with Twilio or other SMS gateway:
    // await TwilioService.sendSMS(phoneNumber, message);
  }

  Future<void> _sendNotificationToPatient(Appointment appointment, String title, String body) async {
    // In a real implementation, this would integrate with Firebase Cloud Messaging
    // For now, we'll simulate the notification
    print('[NOTIFICATION] To Patient ${appointment.patientId}: $title - $body');
    
    // You would implement actual FCM notification sending here
    // Example: await FirebaseMessaging.instance.sendMessage(...)
  }

  Future<void> completeSession(String appointmentId) async {
    try {
      // Update appointment status locally
      var appointment = _allPatientQueue.firstWhere((appt) => appt.id == appointmentId, orElse: () => _allPatientQueue.first);
      appointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        hospitalId: appointment.hospitalId,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        department: appointment.department,
        reason: appointment.reason,
        status: AppointmentStatus.completed,
        queuePosition: appointment.queuePosition,
        createdAt: appointment.createdAt,
        updatedAt: DateTime.now(),
        isEmergency: appointment.isEmergency,
      );
      
      // Update the queue
      _allPatientQueue[_allPatientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      _patientQueue[_patientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      
      _isSessionActive = false;
      notifyListeners();
    } catch (e) {
      print('Error completing session: $e');
      _errorMessage = 'Failed to complete session: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> completeNextAppointment() async {
    try {
      if (_patientQueue.isNotEmpty) {
        final nextAppointment = _patientQueue.firstWhere(
          (appt) => appt.status == AppointmentStatus.confirmed || appt.status == AppointmentStatus.inProgress,
          orElse: () => _patientQueue.first,
        );
        
        // Update appointment status locally
        var appointment = _allPatientQueue.firstWhere((appt) => appt.id == nextAppointment.id, orElse: () => _allPatientQueue.first);
        appointment = Appointment(
          id: appointment.id,
          patientId: appointment.patientId,
          doctorId: appointment.doctorId,
          hospitalId: appointment.hospitalId,
          appointmentDate: appointment.appointmentDate,
          timeSlot: appointment.timeSlot,
          department: appointment.department,
          reason: appointment.reason,
          status: AppointmentStatus.completed,
          queuePosition: appointment.queuePosition,
          createdAt: appointment.createdAt,
          updatedAt: DateTime.now(),
          isEmergency: appointment.isEmergency,
        );
        
        // Update the queues
        _allPatientQueue[_allPatientQueue.indexWhere((appt) => appt.id == nextAppointment.id)] = appointment;
        _patientQueue.removeWhere((appt) => appt.id == nextAppointment.id);
      }
      notifyListeners();
    } catch (e) {
      print('Error completing next appointment: $e');
      _errorMessage = 'Failed to complete next appointment: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await QueueService.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
      // Refresh queues after status change
      await refreshQueues(_currentDoctorId, _currentClinicId);
      notifyListeners();
    } catch (e) {
      print('Error cancelling appointment: $e');
      _errorMessage = 'Failed to cancel appointment: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updatePatientStatus(String appointmentId, AppointmentStatus status) async {
    try {
      // Update appointment status locally
      var appointment = _patientQueue.firstWhere((appt) => appt.id == appointmentId, orElse: () => _patientQueue.first);
      appointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        hospitalId: appointment.hospitalId,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        department: appointment.department,
        reason: appointment.reason,
        status: status,
        queuePosition: appointment.queuePosition,
        createdAt: appointment.createdAt,
        updatedAt: DateTime.now(),
        isEmergency: appointment.isEmergency,
      );
      
      // Update the queue
      _patientQueue[_patientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      _allPatientQueue[_allPatientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      
      notifyListeners();
    } catch (e) {
      print('Error updating patient status: $e');
      _errorMessage = 'Failed to update patient status: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> updatePatientPosition(String appointmentId, int position) async {
    try {
      // Update appointment position locally
      var appointment = _patientQueue.firstWhere((appt) => appt.id == appointmentId, orElse: () => _patientQueue.first);
      appointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        hospitalId: appointment.hospitalId,
        appointmentDate: appointment.appointmentDate,
        timeSlot: appointment.timeSlot,
        department: appointment.department,
        reason: appointment.reason,
        status: appointment.status,
        queuePosition: position,
        createdAt: appointment.createdAt,
        updatedAt: DateTime.now(),
        isEmergency: appointment.isEmergency,
      );
      
      // Update the queue
      _patientQueue[_patientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      _allPatientQueue[_allPatientQueue.indexWhere((appt) => appt.id == appointmentId)] = appointment;
      
      notifyListeners();
    } catch (e) {
      print('Error updating patient position: $e');
      _errorMessage = 'Failed to update patient position: ${e.toString()}';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
