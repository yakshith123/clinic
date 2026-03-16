// Removed Firebase import

enum ResourceType { equipment, medication, staff, room }

class Resource {
  final String id;
  final String name;
  final String company;
  final String contactPerson;
  final String contactPhone;
  final String contactEmail;
  final ResourceType type;
  final String doctorId;
  final String hospitalId;
  final DateTime scheduledDate;
  final String timeSlot;
  final bool isApproved;
  final DateTime? checkInTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Resource({
    required this.id,
    required this.name,
    required this.company,
    required this.contactPerson,
    required this.contactPhone,
    required this.contactEmail,
    required this.type,
    required this.doctorId,
    required this.hospitalId,
    required this.scheduledDate,
    required this.timeSlot,
    this.isApproved = false,
    this.checkInTime,
    this.startTime,
    this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      company: map['company'] ?? '',
      contactPerson: map['contactPerson'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      type: ResourceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ResourceType.equipment,
      ),
      doctorId: map['doctorId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      scheduledDate: map['scheduledDate'] != null ? DateTime.parse(map['scheduledDate']) : DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      isApproved: map['is_approved'] ?? false,
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
      'name': name,
      'company': company,
      'contactPerson': contactPerson,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'type': type.name,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'is_approved': isApproved,
      'checkInTime': checkInTime?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Resource copyWith({
    String? id,
    String? name,
    String? company,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    ResourceType? type,
    String? doctorId,
    String? hospitalId,
    DateTime? scheduledDate,
    String? timeSlot,
    bool? isApproved,
    DateTime? checkInTime,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Resource(
      id: id ?? this.id,
      name: name ?? this.name,
      company: company ?? this.company,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      type: type ?? this.type,
      doctorId: doctorId ?? this.doctorId,
      hospitalId: hospitalId ?? this.hospitalId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      isApproved: isApproved ?? this.isApproved,
      checkInTime: checkInTime ?? this.checkInTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}