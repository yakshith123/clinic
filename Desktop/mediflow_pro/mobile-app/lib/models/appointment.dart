// Removed Firebase import

enum AppointmentStatus { pending, confirmed, inProgress, completed, cancelled }

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String hospitalId;
  final DateTime appointmentDate;
  final String timeSlot;
  final String department;
  final String reason;
  final String? notes;
  final AppointmentStatus status;
  final bool isEmergency;
  final int queuePosition;
  final double? patientLatitude;
  final double? patientLongitude;
  final DateTime? checkInTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.department,
    required this.reason,
    this.notes,
    required this.status,
    this.isEmergency = false,
    this.queuePosition = 0,
    this.patientLatitude,
    this.patientLongitude,
    this.checkInTime,
    this.startTime,
    this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      appointmentDate: map['appointmentDate'] != null ? DateTime.parse(map['appointmentDate']) : DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      department: map['department'] ?? '',
      reason: map['reason'] ?? '',
      notes: map['notes'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      isEmergency: map['isEmergency'] ?? false,
      queuePosition: map['queuePosition'] ?? 0,
      patientLatitude: map['patientLatitude']?.toDouble(),
      patientLongitude: map['patientLongitude']?.toDouble(),
      checkInTime: map['checkInTime'] != null ? DateTime.parse(map['checkInTime']) : null,
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'department': department,
      'reason': reason,
      'notes': notes,
      'status': status.name,
      'isEmergency': isEmergency,
      'queuePosition': queuePosition,
      'patientLatitude': patientLatitude,
      'patientLongitude': patientLongitude,
      'checkInTime': checkInTime?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? hospitalId,
    DateTime? appointmentDate,
    String? timeSlot,
    String? department,
    String? reason,
    String? notes,
    AppointmentStatus? status,
    bool? isEmergency,
    int? queuePosition,
    double? patientLatitude,
    double? patientLongitude,
    DateTime? checkInTime,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      hospitalId: hospitalId ?? this.hospitalId,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      department: department ?? this.department,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      isEmergency: isEmergency ?? this.isEmergency,
      queuePosition: queuePosition ?? this.queuePosition,
      patientLatitude: patientLatitude ?? this.patientLatitude,
      patientLongitude: patientLongitude ?? this.patientLongitude,
      checkInTime: checkInTime ?? this.checkInTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}