// lib/models/profiles/student_profile.dart

import 'package:flutter/material.dart';

class StudentProfile {
  final String studentId;
  final String name;
  final double attendancePercentage;
  final double latestGrade;
  final String financialStatus;
  final String riskStatus;

  StudentProfile({
    required this.studentId,
    required this.name,
    required this.attendancePercentage,
    required this.latestGrade,
    required this.financialStatus,
    required this.riskStatus,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: json['student_id'],
      name: json['name'],
      attendancePercentage: (json['attendance_percentage'] as num).toDouble(),
      latestGrade: (json['latest_grade'] as num).toDouble(),
      financialStatus: json['financial_status'],
      riskStatus: json['risk_status'],
    );
  }

  Color get riskColor {
    switch (riskStatus) {
      case 'High Risk':
        return Colors.red.shade700;
      case 'Medium Risk':
        return Colors.orange.shade700;
      case 'Low Risk':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}