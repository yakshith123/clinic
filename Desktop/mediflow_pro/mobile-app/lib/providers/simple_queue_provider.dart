import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/resource.dart';
import '../models/clinic.dart';

class SimpleQueueProvider extends ChangeNotifier {
  List<Appointment> _patientQueue = [];
  List<Resource> _resourceQueue = [];
  Clinic? _currentClinic;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSessionActive = false;

  // Getters
  List<Appointment> get patientQueue => _patientQueue;
  List<Resource> get resourceQueue => _resourceQueue;
  Clinic? get currentClinic => _currentClinic;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSessionActive => _isSessionActive;
  int get totalQueueCount => _patientQueue.length + _resourceQueue.length;
  
  // Filtered getters - exclude completed and cancelled appointments
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

  // Queue Management
  Future<void> loadQueues(String doctorId, String hospitalId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Comprehensive mock data for testing
      final now = DateTime.now();
      
      _patientQueue = [
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
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startSession() async {
    if (_patientQueue.isEmpty && _resourceQueue.isEmpty) {
      _setError('No appointments or resources in queue');
      return;
    }

    _isSessionActive = true;
    await _updateQueuePositions();
    await _sendInitialNotifications();
    await _sendSessionStartNotifications();
    notifyListeners();
  }

  Future<void> stopSession() async {
    _isSessionActive = false;
    notifyListeners();
  }

  Future<void> completeNextAppointment() async {
    if (_patientQueue.isEmpty) return;

    try {
      // Remove from queue
      _patientQueue.removeAt(0);
      
      // Send notification to next patient
      await _notifyNextInQueue();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> completeNextResource() async {
    if (_resourceQueue.isEmpty) return;

    try {
      // Remove from queue
      _resourceQueue.removeAt(0);
      
      // Send notification to next resource
      await _notifyNextResource();
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Mock notification methods
  Future<void> _sendInitialNotifications() async {
    // In a real app, this would send actual notifications
    print('Sending initial notifications to first 5 patients');
  }

  Future<void> _sendSessionStartNotifications() async {
    // Send notifications to patients when session starts
    for (var appointment in _patientQueue.take(5)) {
      print('[NOTIFICATION] To Patient ${appointment.patientId}: Session Started - '
            'Your doctor\'s session has started. You are #${appointment.queuePosition} in queue.');
    }
    print('Sent session start notifications to ${_patientQueue.length > 5 ? 5 : _patientQueue.length} patients');
  }

  Future<void> _notifyNextInQueue() async {
    if (_patientQueue.isNotEmpty) {
      print('Notifying next patient: ${_patientQueue.first.reason}');
    }
  }

  Future<void> _notifyNextResource() async {
    if (_resourceQueue.isNotEmpty) {
      print('Notifying next resource: ${_resourceQueue.first.name}');
    }
  }

  Future<void> _updateQueuePositions() async {
    // In a real app, this would update queue positions in the database
    print('Updating queue positions');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}