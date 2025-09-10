// lib/providers/counselor_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/counseling_session.dart';
import '../models/profiles/student_profile.dart'; // Import student profile

class CounselorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StudentProfile> _allStudents = []; // List for counselors to see all students
  List<CounselingSession> _studentSessions = []; // Sessions for a specific student
  bool _isLoading = false;
  String? _errorMessage;

  List<StudentProfile> get allStudents => _allStudents;
  List<CounselingSession> get studentSessions => _studentSessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all students for the counselor to choose from
  Future<void> fetchAllStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allStudents = await _apiService.getAllStudents();
    } catch (e) {
      _errorMessage = "Failed to load students for counseling.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Fetch counseling sessions for a specific student (used when viewing student detail)
  Future<void> fetchSessionsForStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _studentSessions = await _apiService.getSessionsForStudent(studentId);
    } catch (e) {
      _errorMessage = "Failed to load counseling sessions.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSession(String studentId, String notes) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Backend defaults status to 'Open'
      await _apiService.createSession(studentId, notes);
      // After creating, re-fetch sessions for the student to update the UI
      await fetchSessionsForStudent(studentId);
      _errorMessage = null; // Clear any previous error
    } catch (e) {
      _errorMessage = "Failed to create session: $e";
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Corrected: status parameter is now SessionStatus, then converted to String for API
  Future<void> updateSession(String sessionId, String notes, String statusString, String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Pass the statusString directly to the API
      await _apiService.updateSession(sessionId, notes, statusString);
      // After updating, re-fetch sessions for the student to update the UI
      await fetchSessionsForStudent(studentId);
      _errorMessage = null; // Clear any previous error
    } catch (e) {
      _errorMessage = "Failed to update session: $e";
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearData() {
    _allStudents = [];
    _studentSessions = [];
    _errorMessage = null;
    notifyListeners();
  }
}