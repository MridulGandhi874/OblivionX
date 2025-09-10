// lib/models/class_profile.dart

class ClassProfile {
  final String classId;
  final String className;
  final String facultyId;
  final List<String> studentIds;

  ClassProfile({
    required this.classId,
    required this.className,
    required this.facultyId,
    required this.studentIds,
  });

  factory ClassProfile.fromJson(Map<String, dynamic> json) {
    return ClassProfile(
      classId: json['class_id'],
      className: json['class_name'],
      facultyId: json['faculty_id'],
      // Ensure student_ids is treated as a List of Strings
      studentIds: List<String>.from(json['student_ids'] ?? []),
    );
  }
}