// Removed Firebase import

enum UserRole { admin, doctor, patient, consultant }

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? hospitalId; // Primary hospital ID
  final List<String>? associatedClinicIds; // Multiple clinics a doctor is associated with
  final String? department;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.hospitalId,
    this.associatedClinicIds,
    this.department,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle role parsing - backend returns role as string
    UserRole role;
    if (map['role'] is String) {
      try {
        role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == map['role'].toLowerCase(),
        );
      } catch (e) {
        role = UserRole.patient; // Default fallback
      }
    } else {
      role = UserRole.patient;
    }

    // Handle associated clinic IDs
    List<String>? associatedClinicIds;
    if (map['associated_clinic_ids'] != null && map['associated_clinic_ids'] is List) {
      associatedClinicIds = List<String>.from(map['associated_clinic_ids']);
    } else if (map['clinic_id'] != null && map['clinic_id'] is String && map['clinic_id'].isNotEmpty) {
      // Use clinic_id as single associated clinic
      associatedClinicIds = [map['clinic_id']];
    }

    return User(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: role,
      hospitalId: map['clinic_id'], // Map clinic_id to hospitalId
      associatedClinicIds: associatedClinicIds,
      department: map['department'],
      createdAt: map['created_at'] != null 
          ? (map['created_at'] is DateTime 
              ? map['created_at']
              : (map['created_at'] is String 
                  ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
                  : DateTime.now()))
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? (map['updated_at'] is DateTime
              ? map['updated_at']
              : (map['updated_at'] is String
                  ? DateTime.tryParse(map['updated_at']) ?? DateTime.now()
                  : DateTime.now()))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'hospital_id': hospitalId,
      'associated_clinic_ids': associatedClinicIds, // Store multiple clinic associations
      'department': department,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? hospitalId,
    List<String>? associatedClinicIds,
    String? department,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      hospitalId: hospitalId ?? this.hospitalId,
      associatedClinicIds: associatedClinicIds ?? this.associatedClinicIds,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Update to current time when changed
    );
  }
}