class EmergencyHistoryItem {
  final int id;
  final String type;
  final String status;
  final DateTime createdAt;
  final String? notes;

  const EmergencyHistoryItem({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory EmergencyHistoryItem.fromJson(Map<String, dynamic> json) {
    return EmergencyHistoryItem(
      id: json['id'] as int,
      type: (json['type'] as String?) ?? 'unknown',
      status: (json['status'] as String?) ?? 'unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'user_id': userId,
      'type': type,
      'status': status,
      'notes': notes,
      // created_at is usually default now() in DB; leave it out.
    };
  }
}
