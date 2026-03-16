class Ad {
  final String? id;
  final String title;
  final String imageUrl;
  final String? targetUrl;
  final String adType;
  final bool isActive;
  final int priority;
  final String? clinicId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? localAssetPath; // NEW: Support for local assets

  Ad({
    this.id,
    required this.title,
    this.imageUrl = '',
    this.targetUrl,
    this.adType = 'banner',
    this.isActive = true,
    this.priority = 0,
    this.clinicId,
    this.startDate,
    this.endDate,
    this.localAssetPath, // NEW
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      id: json['id'],
      title: json['title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      targetUrl: json['target_url'],
      adType: json['ad_type'] ?? 'banner',
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
      clinicId: json['clinic_id'],
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : null,
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : null,
      localAssetPath: json['local_asset_path'], // NEW
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'target_url': targetUrl,
      'ad_type': adType,
      'is_active': isActive,
      'priority': priority,
      'clinic_id': clinicId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'local_asset_path': localAssetPath, // NEW
    };
  }
}
