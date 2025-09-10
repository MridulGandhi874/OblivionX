// lib/providers/student_provider.dart

import 'package:flutter/material.dart';
import '../models/profiles/student_profile.dart';
import '../models/counseling_session.dart'; // <-- IMPORT THE NEW MODEL
import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Data for different dashboards
  List<StudentProfile> _students = []; // For faculty view
  StudentProfile? _currentStudent; // For student view
  List<CounselingSession> _sessions = []; // <-- NEW: For session history

  // State management
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<StudentProfile> get students => _students;
  StudentProfile? get currentStudent => _currentStudent;
  List<CounselingSession> get sessions => _sessions; // <-- NEW GETTER
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // For Faculty/Counselor: Fetches all students
  Future<void> fetchAllStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _students = await _apiService.getAllStudents();
    } catch (e) {
      _errorMessage = "Failed to load student data.";
    }
    _isLoading = false;
    notifyListeners();
  }

  // For Student: Fetches only their own data
  Future<void> fetchMyData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Fetch personal data and counseling sessions at the same time
      final results = await Future.wait([
        _apiService.getMyStudentData(),
        // We need the student's ID to fetch sessions, so we do it in steps
      ]);
      _currentStudent = results[0];
      if (_currentStudent != null) {
        _sessions = await _apiService.getSessionsForStudent(_currentStudent!.studentId);
      }
    } catch (e) {
      _errorMessage = "Failed to load your personal data.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // NEW: For Faculty/Counselor to view a student's sessions
  Future<void> fetchSessionsForStudent(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _sessions = await _apiService.getSessionsForStudent(studentId);
    } catch (e) {
      _errorMessage = "Failed to load session history.";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearData() {
    _students = [];
    _currentStudent = null;
    _sessions = []; // <-- CLEAR SESSIONS ON LOGOUT
    notifyListeners();
  }
}