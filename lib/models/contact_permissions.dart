
class ContactPermissions {
  final int id;
  final String? ownerId;
  final String? viewerId;
  final String? contactUserId;

  final bool canViewProfile;
  final bool canViewLocation;
  final bool canViewMedicalInfo;

  final bool canViewBasicProfile;
  final bool canViewEmergencyInfo;
  final bool canViewStatus;
  final bool canViewMedical;

  ContactPermissions({
    required this.id,
    required this.ownerId,
    required this.viewerId,
    required this.contactUserId,
    required this.canViewProfile,
    required this.canViewLocation,
    required this.canViewMedicalInfo,
    required this.canViewBasicProfile,
    required this.canViewEmergencyInfo,
    required this.canViewStatus,
    required this.canViewMedical,
  });

  factory ContactPermissions.fromJson(Map<String, dynamic> json) {
    return ContactPermissions(
      id: (json['id'] as num).toInt(),
      ownerId: json['owner_id'] as String?,
      viewerId: json['viewer_id'] as String?,
      contactUserId: json['contact_user_id'] as String?,
      canViewProfile: json['can_view_profile'] as bool? ?? true,
      canViewLocation: json['can_view_location'] as bool? ?? false,
      canViewMedicalInfo: json['can_view_medical_info'] as bool? ?? false,
      canViewBasicProfile: json['can_view_basic_profile'] as bool? ?? true,
      canViewEmergencyInfo: json['can_view_emergency_info'] as bool? ?? false,
      canViewStatus: json['can_view_status'] as bool? ?? true,
      canViewMedical: json['can_view_medical'] as bool? ?? true,
    );
  }
}
