class CachedEmergencyMeta {
  final int id;
  final bool isFavorite;
  final bool isArchived;

  const CachedEmergencyMeta({
    required this.id,
    required this.isFavorite,
    required this.isArchived,
  });
}

class CachedEmergency {
  final int id;
  final String type;
  final String status;
  final String? locationDetails;
  final String? notes;
  final String? reportByAi;
  final DateTime? createdAt;
  final bool isFavorite;
  final bool isArchived;

  const CachedEmergency({
    required this.id,
    required this.type,
    required this.status,
    this.locationDetails,
    this.notes,
    this.reportByAi,
    this.createdAt,
    this.isFavorite = false,
    this.isArchived = false,
  });

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'type': type,
      'status': status,
      'location_details': locationDetails,
      'notes': notes,
      'report_by_ai': reportByAi,
      'created_at': createdAt?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory CachedEmergency.fromDb(Map<String, dynamic> row) {
    DateTime? dt;
    final raw = row['created_at']?.toString();
    if (raw != null && raw.isNotEmpty) {
      try {
        dt = DateTime.parse(raw);
      } catch (_) {}
    }
    return CachedEmergency(
      id: (row['id'] as num).toInt(),
      type: (row['type'] ?? '').toString(),
      status: (row['status'] ?? '').toString(),
      locationDetails: row['location_details']?.toString(),
      notes: row['notes']?.toString(),
      reportByAi: row['report_by_ai']?.toString(),
      createdAt: dt,
      isFavorite: (row['is_favorite'] as num?) == 1,
      isArchived: (row['is_archived'] as num?) == 1,
    );
  }
}
