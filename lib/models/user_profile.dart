class UserProfile {
  final String id;
  final String? fullName;
  final String? phone;
  final String? profileImageUrl;
  final String? profileStatus;

  final int? age;
  final String? gender;
  final double? weightKg;
  final double? heightCm;

  final String? bloodType;
  final String? allergies;
  final String? chronicConditions;
  final String? medications;
  final String? disabilities;
  final String? preferredHospital;
  final String? otherNotes;

  UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.profileImageUrl,
    this.profileStatus,
    this.age,
    this.gender,
    this.weightKg,
    this.heightCm,
    this.bloodType,
    this.allergies,
    this.chronicConditions,
    this.medications,
    this.disabilities,
    this.preferredHospital,
    this.otherNotes,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      profileStatus: json['profile_status'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      bloodType: json['blood_type'] as String?,
      allergies: json['allergies'] as String?,
      chronicConditions: json['chronic_conditions'] as String?,
      medications: json['medications'] as String?,
      disabilities: json['disabilities'] as String?,
      preferredHospital: json['preferred_hospital'] as String?,
      otherNotes: json['other_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'profile_status': profileStatus,
      'age': age,
      'gender': gender,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'blood_type': bloodType,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'medications': medications,
      'disabilities': disabilities,
      'preferred_hospital': preferredHospital,
      'other_notes': otherNotes,
    };
  }
}
