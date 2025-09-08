// lib/models/profiles/faculty_profile.dart

class FacultyProfile {
  final String facultyId;
  final String name;
  final String department;

  FacultyProfile({
    required this.facultyId,
    required this.name,
    required this.department,
  });

  factory FacultyProfile.fromJson(Map<String, dynamic> json) {
    return FacultyProfile(
      facultyId: json['faculty_id'],
      name: json['name'],
      department: json['department'],
    );
  }
}