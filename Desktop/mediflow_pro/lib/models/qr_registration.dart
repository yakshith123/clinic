class QrRegistration {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String mobileNumber;
  final String hospitalId;
  final String hospitalName;
  final String symptoms;
  final String visitType;
  final String status;
  final DateTime createdAt;

  QrRegistration({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.mobileNumber,
    required this.hospitalId,
    required this.hospitalName,
    required this.symptoms,
    required this.visitType,
    required this.status,
    required this.createdAt,
  });

  factory QrRegistration.fromMap(Map<String, dynamic> map) {
    return QrRegistration(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      fullName: map['fullName'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      symptoms: map['symptoms'] ?? '',
      visitType: map['visitType'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['createdAt'] != null && map['createdAt'].toString().isNotEmpty
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'symptoms': symptoms,
      'visitType': visitType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  QrRegistration copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    String? mobileNumber,
    String? hospitalId,
    String? hospitalName,
    String? symptoms,
    String? visitType,
    String? status,
    DateTime? createdAt,
  }) {
    return QrRegistration(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      symptoms: symptoms ?? this.symptoms,
      visitType: visitType ?? this.visitType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}