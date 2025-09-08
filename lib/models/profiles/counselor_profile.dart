// lib/models/profiles/counselor_profile.dart

class CounselorProfile {
  final String counselorId;
  final String name;
  final String specialization;

  CounselorProfile({
    required this.counselorId,
    required this.name,
    required this.specialization,
  });

  factory CounselorProfile.fromJson(Map<String, dynamic> json) {
    return CounselorProfile(
      counselorId: json['counselor_id'],
      name: json['name'],
      specialization: json['specialization'],
    );
  }
}