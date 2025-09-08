// lib/providers/admin_provider.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/profiles/student_profile.dart';
import '../models/profiles/faculty_profile.dart';
import '../models/profiles/counselor_profile.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StudentProfile> _students = [];
  List<FacultyProfile> _faculty = [];
  List<CounselorProfile> _counselors = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<StudentProfile> get students => _students;
  List<FacultyProfile> get faculty => _faculty;
  List<CounselorProfile> get counselors => _counselors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --- THIS IS THE DEBUGGING BLOCK ---
      // We will fetch each list one by one to find the error.

      print("Step 1: Fetching students...");
      _students = await _apiService.getAllStudents();
      print("✅ Success: Fetched ${_students.length} students.");

      print("Step 2: Fetching faculty...");
      _faculty = await _apiService.getAllFaculty();
      print("✅ Success: Fetched ${_faculty.length} faculty members.");

      print("Step 3: Fetching counselors...");
      _counselors = await _apiService.getAllCounselors();
      print("✅ Success: Fetched ${_counselors.length} counselors.");

    } catch (e) {
      // This will now print a much more specific error.
      _errorMessage = "Failed to load dashboard data. Please try again.";
      print("🔥 AN ERROR OCCURRED: $e"); // This is the crucial line
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearAllData() {
    _students = [];
    _faculty = [];
    _counselors = [];
    notifyListeners();
  }
}