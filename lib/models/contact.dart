class Contact {
  final int? id;

  ///contacts.owner_id (auth.users.id)
  final String? ownerId;

  final String? contactUserId;

  final String name;

  final String? phone;
  final String? email;
  final String? relation;

  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? avatarUrl;
  final String? notes;
  final bool isPrimary;

  const Contact({
    this.id,
    this.ownerId,
    this.contactUserId,
    required this.name,
    this.phone,
    this.email,
    this.relation,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.notes,
    this.isPrimary = false,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: (json['id'] as num?)?.toInt(),
      ownerId: json['owner_id'] as String?,
      contactUserId: json['contact_user_id'] as String?,
      name: (json['contact_name'] as String?) ?? '',
      phone: json['contact_phone'] as String?,
      email: json['contact_email'] as String?,
      relation: json['relation'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      notes: json['notes'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap({
    required String ownerId,
    String? resolvedContactUserId,
  }) {
    return {
      'owner_id': ownerId,
      'contact_user_id': resolvedContactUserId ?? contactUserId,
      'contact_name': name,
      'contact_phone': phone,
      'contact_email': email,
      'relation': relation,
      'status': status,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'contact_name': name,
      'contact_phone': phone,
      'contact_email': email,
      'relation': relation,
      'status': status,
      'contact_user_id': contactUserId,
    };
  }

  Contact copyWith({
    int? id,
    String? ownerId,
    String? contactUserId,
    String? name,
    String? phone,
    String? email,
    String? relation,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
    String? notes,
    bool? isPrimary,
  }) {
    return Contact(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      contactUserId: contactUserId ?? this.contactUserId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relation: relation ?? this.relation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      notes: notes ?? this.notes,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
