class Contact {
  final String id;
  final String? ownerId;
  final String? contactUserId;
  final String name;
  final String? relation;
  final String? phone;
  final String? email;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? avatarUrl;
  final String? notes;
  final bool isPrimary;

  Contact({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.status,
    this.contactUserId,
    this.relation,
    this.phone,
    this.email,
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.notes,
    this.isPrimary = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'].toString(),
      ownerId: json['owner_id'] as String?,
      contactUserId: json['contact_user_id'] as String?,
      name: json['contact_name'] as String,
      relation: json['relation'] as String?,
      phone: json['contact_phone'] as String?,
      email: json['contact_email'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      avatarUrl: json['avatar_url'] as String?,
      notes: json['notes'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap(String ownerId) {
    return {
      'owner_id': ownerId,
      'contact_user_id': contactUserId,
      'contact_name': name,
      'relation': relation,
      'contact_phone': phone,
      'contact_email': email,
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'contact_name': name,
      'relation': relation,
      'contact_phone': phone,
      'contact_email': email,
      'status': status,
    };
  }
}
