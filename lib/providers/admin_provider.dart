// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/profiles/student_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/counselor_profile.dart';
import '../models/class_profile.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StudentProfile> _students = [];
  List<FacultyProfile> _faculty = [];
  List<CounselorProfile> _counselors = [];
  List<ClassProfile> _classes = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<StudentProfile> get students => _students;
  List<FacultyProfile> get faculty => _faculty;
  List<CounselorProfile> get counselors => _counselors;
  List<ClassProfile> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getAllStudents(),
        _apiService.getAllFaculty(),
        _apiService.getAllCounselors(),
        _apiService.getAllClasses(),
      ]);

      _students = results[0] as List<StudentProfile>;
      _faculty = results[1] as List<FacultyProfile>;
      _counselors = results[2] as List<CounselorProfile>;
      _classes = results[3] as List<ClassProfile>;

    } catch (e) {
      _errorMessage = "Failed to load dashboard data. Please try again.";
      print(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Admin can update student financial status
  Future<void> updateStudentFinancialStatus(String studentId, String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedStudent = await _apiService.updateFinancialStatus(studentId, newStatus);
      // Find and replace the updated student in the list
      int index = _students.indexWhere((s) => s.studentId == studentId);
      if (index != -1) {
        _students[index] = updatedStudent;
      }
    } catch (e) {
      _errorMessage = "Failed to update financial status: $e";
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearAllData() {
    _students = [];
    _faculty = [];
    _counselors = [];
    _classes = [];
    _errorMessage = null; // Clear error message too
    notifyListeners();
  }
}