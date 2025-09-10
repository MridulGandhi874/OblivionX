// lib/models/counseling_session.dart

import 'package:flutter/material.dart'; // For Color in the extension

enum SessionStatus {
  open,
  closed,
}

class CounselingSession {
  final String sessionId;
  final String studentId;
  final String initiatorId;
  final DateTime sessionDate;
  final String notes;
  final SessionStatus status; // Use the enum type

  CounselingSession({
    required this.sessionId,
    required this.studentId,
    required this.initiatorId,
    required this.sessionDate,
    required this.notes,
    required this.status,
  });

  factory CounselingSession.fromJson(Map<String, dynamic> json) {
    return CounselingSession(
      sessionId: json['session_id'],
      studentId: json['student_id'],
      initiatorId: json['initiator_id'],
      sessionDate: DateTime.parse(json['session_date']),
      notes: json['notes'],
      status: SessionStatus.values.firstWhere(
            (e) => e.toString().split('.').last == json['status'],
        orElse: () => SessionStatus.open, // Default or error handling
      ),
    );
  }
}

// Extension to help with SessionStatus to Color mapping, moved here for global access
extension SessionStatusExtension on SessionStatus {
  Color get statusColor {
    switch (this) {
      case SessionStatus.open:
        return Colors.orange;
      case SessionStatus.closed:
        return Colors.green;
    // No default needed if all enum values are covered
    }
  }
}