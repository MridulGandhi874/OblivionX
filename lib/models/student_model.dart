import 'package:flutter/material.dart';

class Student {
  final String studentId;
  final String name;
  double attendancePercentage;
  final double latestGrade;
  String riskStatus;

  Student({
    required this.studentId,
    required this.name,
    required this.attendancePercentage,
    required this.latestGrade,
    required this.riskStatus,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'],
      name: json['name'],
      attendancePercentage: (json['attendance_percentage'] as num).toDouble(),
      latestGrade: (json['latest_grade'] as num).toDouble(),
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