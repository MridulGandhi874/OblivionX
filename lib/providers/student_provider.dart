// lib/providers/student_provider.dart

import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/api_service.dart';

class StudentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Student> _students = [];
  Student? _currentStudent;
  bool _isLoading = false;
  String? _errorMessage;

  List<Student> get students => _students;
  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // For Faculty/Admin: Fetches all students
  Future<void> fetchAllStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _students = await _apiService.getAllStudents();
    } catch (e) {
      _errorMessage = "Failed to load student data.";
      print(e);
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
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  // Called when logging out to clear data
  void clearData() {
    _students = [];
    _currentStudent = null;
    _errorMessage = null;
    notifyListeners();
  }
}