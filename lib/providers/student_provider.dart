// lib/providers/student_provider.dart

import 'package:flutter/material.dart';
import '../models/profiles/student_profile.dart';
import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<StudentProfile> _students = []; // For faculty view
  StudentProfile? _currentStudent; // For student view
  bool _isLoading = false;
  String? _errorMessage;

  List<StudentProfile> get students => _students;
  StudentProfile? get currentStudent => _currentStudent;
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
      _currentStudent = await _apiService.getMyStudentData();
    } catch (e) {
      _errorMessage = "Failed to load your personal data.";
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearData() {
    _students = [];
    _currentStudent = null;
    notifyListeners();
  }
}